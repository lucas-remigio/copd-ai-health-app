import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AIService {
  CactusLM? _model;
  bool _isInitialized = false;
  Function(double)? onDownloadProgress;

  static const String _modelUrl =
      'https://huggingface.co/lucasxvr/quantized_gemma3n_finetuned_health_test/resolve/main/gemma-3n-finetuned-Q4_K_M.gguf';
  static const String _modelFileName = 'gemma-3n-finetuned-Q4_K_M.gguf';

  // Initialize the AI model
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🤖 Initializing AI model...');

    final modelPath = await _downloadModel();
    await _loadModel(modelPath);

    _isInitialized = true;
    debugPrint('✅ AI model ready!');
  }

  // Download model with progress tracking
  Future<String> _downloadModel() async {
    final modelFile = await _getModelFile();

    if (await modelFile.exists()) {
      debugPrint('✅ Model found at: ${modelFile.path}');
      return modelFile.path;
    }

    debugPrint('📥 Downloading model (5-10 min)...');
    await _downloadWithProgress(modelFile);
    return modelFile.path;
  }

  // Get model file path - FIXED
  Future<File> _getModelFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelPath = '${appDir.path}/$_modelFileName';
    debugPrint('📁 Model path: $modelPath');
    return File(modelPath);
  }

  // Download with throttled progress updates
  Future<void> _downloadWithProgress(File modelFile) async {
    final request = http.Request('GET', Uri.parse(_modelUrl));
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Download failed: ${response.statusCode}');
    }

    final contentLength = response.contentLength ?? 0;
    final sink = modelFile.openWrite();
    int downloadedBytes = 0;
    DateTime lastLogTime = DateTime.now();

    try {
      await response.stream
          .listen(
            (chunk) {
              downloadedBytes += chunk.length;
              sink.add(chunk);

              // Log every 5 seconds
              final now = DateTime.now();
              if (now.difference(lastLogTime).inSeconds >= 5) {
                _logProgress(downloadedBytes, contentLength);
                lastLogTime = now;
              }

              // Update UI callback
              if (contentLength > 0) {
                onDownloadProgress?.call(downloadedBytes / contentLength);
              }
            },
            onError: (error) async {
              await sink.close();
              if (await modelFile.exists()) await modelFile.delete();
              throw error;
            },
          )
          .asFuture();

      await sink.close();
      debugPrint('✅ Download complete');
    } catch (e) {
      debugPrint('❌ Download failed: $e');
      rethrow;
    }
  }

  // Log download progress
  void _logProgress(int downloaded, int total) {
    final percent = ((downloaded / total) * 100).toStringAsFixed(1);
    final mb = (downloaded / 1024 / 1024).toStringAsFixed(1);
    final totalMb = (total / 1024 / 1024).toStringAsFixed(1);
    debugPrint('📊 $percent% ($mb / $totalMb MB)');
  }

  // Load model into memory
  Future<void> _loadModel(String modelPath) async {
    debugPrint('🔧 Loading model from: $modelPath');

    // Verify file exists
    final file = File(modelPath);
    if (!await file.exists()) {
      throw Exception('Model file not found at: $modelPath');
    }

    final fileSize = await file.length();
    debugPrint(
      '📦 Model file size: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
    );

    try {
      _model = CactusLM();
      await _model!.init(
        modelFilename: modelPath,
        contextSize: 2048,
        threads: 4,
      );
    } catch (e) {
      debugPrint('❌ Model loading failed: $e');
      rethrow;
    }
  }

  // Test model with simple query
  Future<String> getTestResponse() async {
    if (!_isInitialized) await initialize();

    debugPrint('🎯 Testing model...');

    final messages = [
      ChatMessage(role: 'system', content: 'You are a helpful assistant.'),
      ChatMessage(role: 'user', content: 'What is the capital of France?'),
    ];

    try {
      final response = await _model!.completion(messages, maxTokens: 50);
      debugPrint('✅ Response: ${response.text}');
      return response.text;
    } catch (e) {
      debugPrint('❌ Error: $e');
      return 'Test failed: $e';
    }
  }

  void dispose() {
    _model?.dispose();
    _isInitialized = false;
  }
}
