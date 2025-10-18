import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AIService {
  CactusLM? _model;
  bool _isInitialized = false;
  Function(double)? onDownloadProgress;
  DateTime? _lastLogTime;
  int? _totalSizeBytes;

  static const String _modelUrl =
      'https://huggingface.co/lucasxvr/quantized_gemma3n_finetuned_health_test/resolve/main/gemma-3n-finetuned-Q4_K_M.gguf';
  static const String _modelFileName = 'gemma-3n-finetuned-Q4_K_M.gguf';
  static const int _fallbackMinSizeBytes = 2000 * 1024 * 1024; // 2000 MB

  // static const String _modelUrl =
  //     'https://huggingface.co/Cactus-Compute/Qwen3-600m-Instruct-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf';
  // static const String _modelFileName = 'Qwen3-0.6B-Q8_0.gguf';
  // static const int _expectedMinSizeBytes = 300 * 1024 * 1024; // 300 MB

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🤖 Initializing AI model...');

    // Get file size first for validation
    _totalSizeBytes = await _getFileSize(_modelUrl);

    await _validateCachedModel();
    await _downloadModel();
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
    _model = CactusLM();

    final totalMB = (_totalSizeBytes! / 1024 / 1024).toStringAsFixed(1);
    debugPrint('📥 Downloading $totalMB MB...');

    _lastLogTime = DateTime.now();

    final downloaded = await _model!.download(
      modelUrl: _modelUrl,
      modelFilename: _modelFileName,
      onProgress: _handleDownloadProgress,
    );

    if (!downloaded) throw Exception('Download failed');
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

  void _handleDownloadProgress(double? progress, String message, bool isError) {
    if (progress != null) {
      onDownloadProgress?.call(progress);
      _logProgress(progress);
    }
    if (isError) debugPrint('❌ $message');
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
    final initialized = await _model!.init(
      modelFilename: _modelFileName,
      contextSize: 2048,
      threads: 4,
      gpuLayers: 0,
    );
    if (!initialized) throw Exception('Model init failed');
  }

  Future<File> _getModelFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_modelFileName');
  }

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
