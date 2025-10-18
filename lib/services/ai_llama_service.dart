import 'dart:async';

import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AILlamaService {
  LlamaController? _controller;
  bool _isInitialized = false;
  Function(double)? onDownloadProgress;
  DateTime? _lastLogTime;
  int? _totalSizeBytes;

  static const String _modelUrl =
      'https://huggingface.co/lucasxvr/quantized_gemma3n_finetuned_health_test/resolve/main/gemma-3n-finetuned-Q4_K_M.gguf';
  static const String _modelFileName = 'gemma-3n-finetuned-Q4_K_M.gguf';
  static const int _fallbackMinSizeBytes = 2000 * 1024 * 1024; // 2000 MB

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🤖 Initializing AI model using LLAMA!...');

    // Get file size first for validation
    _totalSizeBytes = await _getFileSize(_modelUrl);

    await _validateCachedModel();
    await _downloadModel();
    await _verifyFileIntegrity();
    await _loadModel();

    _isInitialized = true;
    debugPrint('✅ AI model ready!');
  }

  Future<void> _validateCachedModel() async {
    final modelFile = await _getModelFile();
    if (!await modelFile.exists()) return;

    final fileSize = await modelFile.length();
    final sizeMB = (fileSize / 1024 / 1024).toStringAsFixed(1);
    final expectedMB = (_totalSizeBytes! / 1024 / 1024).toStringAsFixed(1);

    debugPrint('📁 Found cached model: $sizeMB MB (expected: $expectedMB MB)');

    if (fileSize < _totalSizeBytes!) {
      debugPrint('⚠️ Corrupted file (incomplete), deleting...');
      await modelFile.delete();
      debugPrint('🗑️ Deleted');
    } else {
      debugPrint('✅ Valid cache');
    }
  }

  Future<void> _downloadModel() async {
    final modelFile = await _getModelFile();
    if (await modelFile.exists()) return; // Already downloaded

    debugPrint('📥 Downloading model...');
    _lastLogTime = DateTime.now();

    final request = http.Request('GET', Uri.parse(_modelUrl));
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Download failed: ${response.statusCode}');
    }

    final sink = modelFile.openWrite();
    int downloadedBytes = 0;

    await response.stream.listen(
      (chunk) {
        downloadedBytes += chunk.length;
        sink.add(chunk);

        final progress = downloadedBytes / _totalSizeBytes!;
        onDownloadProgress?.call(progress);
        _logProgress(progress);
      },
      onError: (error) {
        sink.close();
        if (modelFile.existsSync()) modelFile.deleteSync();
        throw error;
      },
      onDone: () => sink.close(),
    );

    debugPrint('✅ Download complete');
  }

  Future<int> _getFileSize(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      if (response.statusCode == 200) {
        final contentLength = response.headers['content-length'];
        if (contentLength != null) {
          return int.parse(contentLength);
        }
      }
      debugPrint('⚠️ Could not get content-length, using fallback');
      return _fallbackMinSizeBytes;
    } catch (e) {
      debugPrint('⚠️ Could not get file size: $e, using fallback');
      return _fallbackMinSizeBytes;
    }
  }

  void _logProgress(double progress) {
    final now = DateTime.now();
    if (_lastLogTime == null || now.difference(_lastLogTime!).inSeconds >= 5) {
      final downloadedMB = (progress * _totalSizeBytes! / 1024 / 1024)
          .toStringAsFixed(1);
      final totalMB = (_totalSizeBytes! / 1024 / 1024).toStringAsFixed(1);
      debugPrint(
        '📊 $downloadedMB / $totalMB MB (${(progress * 100).toStringAsFixed(1)}%)',
      );
      _lastLogTime = now;
    }
  }

  Future<void> _loadModel() async {
    debugPrint('🔧 Loading model...');

    final modelPath = (await _getModelFile()).path;
    debugPrint('📍 Model path: $modelPath');

    try {
      _controller = LlamaController();
      await _controller!.loadModel(
        modelPath: modelPath,
        threads: 4,
        contextSize: 2048,
      );

      debugPrint('✅ Model loaded successfully');
    } catch (e) {
      debugPrint('❌ Model loading failed: $e');
      rethrow;
    }
  }

  Future<void> _verifyFileIntegrity() async {
    final file = await _getModelFile();
    if (!await file.exists()) {
      debugPrint('❌ Model file does not exist');
      return;
    }

    final size = await file.length();
    debugPrint(
      '📦 Downloaded file size: ${(size / 1024 / 1024).toStringAsFixed(2)} MB',
    );
    debugPrint(
      '📦 Expected size: ${(_totalSizeBytes! / 1024 / 1024).toStringAsFixed(2)} MB',
    );

    if (size != _totalSizeBytes) {
      debugPrint('⚠️ File size mismatch - possible corruption');
      await file.delete();
      debugPrint('🗑️ Deleted corrupted file');
    } else {
      debugPrint('✅ File size matches');
    }
  }

  Future<File> _getModelFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_modelFileName');
  }

  Future<String> getTestResponse() async {
    if (!_isInitialized) await initialize();
    if (_controller == null) throw Exception('Model not loaded');

    debugPrint('🎯 Testing model...');

    const prompt =
        "System: You are a helpful assistant.\nUser: What is the capital of France?\nAssistant:";

    try {
      String fullResponse = '';
      StreamSubscription? subscription;

      subscription = _controller!
          .generate(prompt: prompt, maxTokens: 50, temperature: 0.7)
          .listen(
            (token) {
              fullResponse += token;
              debugPrint('Token: $token'); // Optional: log each token
            },
            onDone: () {
              debugPrint('✅ Generation complete!');
              debugPrint('Full Response: $fullResponse');
            },
            onError: (error) {
              debugPrint('❌ Error during generation: $error');
              throw error;
            },
          );

      // Wait for the stream to complete
      await subscription.asFuture();

      return fullResponse;
    } catch (e) {
      debugPrint('❌ Error: $e');
      return 'Test failed: $e';
    }
  }

  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}
