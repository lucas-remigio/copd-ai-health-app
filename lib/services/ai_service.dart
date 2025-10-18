import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AIService {
  CactusLM? _model;
  bool _isInitialized = false;
  Function(double)? onDownloadProgress;
  DateTime? _lastLogTime;

  // static const String _modelUrl =
  //     'https://huggingface.co/lucasxvr/quantized_gemma3n_finetuned_health_test/resolve/main/gemma-3n-finetuned-Q4_K_M.gguf';
  // static const String _modelFileName = 'gemma-3n-finetuned-Q4_K_M.gguf';

  static const String _modelUrl =
      'https://huggingface.co/Cactus-Compute/Qwen3-600m-Instruct-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf';
  static const String _modelFileName = 'Qwen3-0.6B-Q8_0.gguf';
  static const int _expectedMinSizeBytes = 300 * 1024 * 1024; // 300 MB

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🤖 Initializing AI model...');

    // Check and delete corrupted file before download
    await _validateCachedModel();

    _model = CactusLM();

    debugPrint(
      '📥 Downloading model (${_expectedMinSizeBytes / 1024 / 1024}MB)...',
    );
    _lastLogTime = DateTime.now();

    final downloaded = await _model!.download(
      modelUrl: _modelUrl,
      modelFilename: _modelFileName,
      onProgress: (progress, message, isError) {
        if (progress != null) {
          onDownloadProgress?.call(progress);

          // Log every 5 seconds
          final now = DateTime.now();
          if (_lastLogTime == null ||
              now.difference(_lastLogTime!).inSeconds >= 5) {
            debugPrint('📊 ${(progress * 100).toStringAsFixed(1)}%');
            _lastLogTime = now;
          }
        }
        if (isError) debugPrint('❌ $message');
      },
    );

    if (!downloaded) {
      throw Exception('Failed to download model');
    }

    debugPrint('✅ Download complete');

    debugPrint('🔧 Loading model into memory...');
    final initialized = await _model!.init(
      modelFilename: _modelFileName,
      contextSize: 2048,
      threads: 4,
      gpuLayers: 0,
    );

    if (!initialized) {
      throw Exception('Failed to initialize model');
    }

    _isInitialized = true;
    debugPrint('✅ AI model ready!');
  }

  Future<void> _validateCachedModel() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File('${appDir.path}/$_modelFileName');

      if (await modelFile.exists()) {
        final fileSize = await modelFile.length();
        final sizeMB = (fileSize / 1024 / 1024).toStringAsFixed(1);

        debugPrint('📁 Found cached model: $sizeMB MB');

        if (fileSize < _expectedMinSizeBytes) {
          debugPrint('⚠️ File is corrupted (too small), deleting...');
          await modelFile.delete();
          debugPrint('🗑️ Corrupted file deleted');
        } else {
          debugPrint('✅ Cached model is valid');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error validating cache: $e');
    }
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
