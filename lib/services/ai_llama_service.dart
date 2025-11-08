import 'dart:async';

import 'package:health_test_app/models/place.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

typedef TokenCallback = void Function(String token);

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

    try {
      // Use await for to properly wait for stream completion
      await for (var chunk in response.stream) {
        downloadedBytes += chunk.length;
        sink.add(chunk);

        final progress = downloadedBytes / _totalSizeBytes!;
        onDownloadProgress?.call(progress);
        _logProgress(progress);
      }

      await sink.flush(); // Ensure all data is written
      await sink.close(); // Close the sink

      debugPrint('✅ Download complete');
      debugPrint(
        '📦 Final size: ${(downloadedBytes / 1024 / 1024).toStringAsFixed(2)} MB',
      );
    } catch (e) {
      await sink.close();
      if (await modelFile.exists()) await modelFile.delete();
      debugPrint('❌ Download failed: $e');
      rethrow;
    }
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

  // In ai_llama_service.dart
  Future<String> getTestResponse({TokenCallback? onToken}) async {
    if (!_isInitialized) await initialize();
    if (_controller == null) throw Exception('Model not loaded');

    debugPrint('🎯 Testing model...');

    const prompt =
        "System: You are a helpful assistant. Answer in 1 word and 1 emoji.\nUser: Say hi\nAssistant:";

    try {
      String fullResponse = '';
      StreamSubscription? subscription;

      subscription = _controller!
          .generate(prompt: prompt, maxTokens: 5, temperature: 0.7)
          .listen(
            (token) {
              fullResponse += token;
              debugPrint('Token: $token');
              onToken?.call(token); // Stream each token
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

      await subscription.asFuture();
      return fullResponse;
    } catch (e) {
      debugPrint('❌ Error: $e');
      return 'Test failed: $e';
    }
  }

  String _buildHealthRecommendationPrompt(
    int steps,
    int goal,
    List<String> formattedPlaces,
  ) {
    final neededSteps = goal - steps > 0 ? goal - steps : 0;
    return """
      System: You are a friendly health assistant. Based on the user's current steps, daily goal, and nearby places (with distances in steps), suggest ONE specific place to walk to today. 
      Choose the place with the HIGHEST number of steps among the nearby places to maximize their progress towards the goal, without overexceeding. 
      Calculate how many steps they need to reach their goal and explain how walking to this place helps them get closer. 
      Keep your response concise, motivating, and under 100 words.

      User: I have walked $steps steps so far today. My daily goal is $goal steps, so I need $neededSteps more steps. Nearby places: ${formattedPlaces.join(', ')}. 
      Suggest a place for me to walk to today to help me reach my goal.

      Assistant:""";
  }

  // Add this method to AILlamaService
  Future<String> getHealthRecommendation(
    int steps,
    int goal,
    List<Place> places, {
    TokenCallback? onToken,
  }) async {
    if (!_isInitialized) await initialize();
    if (_controller == null) throw Exception('Model not loaded');

    final formattedPlaces = places
        .map(
          (place) =>
              '${place.name} (${place.distanceInSteps} • ${place.durationInMinutes})',
        )
        .toList();

    debugPrint('🏥 Generating health recommendation...');

    // In ai_llama_service.dart, update the prompt in getHealthRecommendation to ensure it recommends a place that maximizes steps
    final prompt = _buildHealthRecommendationPrompt(
      steps,
      goal,
      formattedPlaces,
    );

    debugPrint('🤖 Prompt: $prompt');

    try {
      String fullResponse = '';
      int maxTokens = 100;
      int tokenCount = 0; // Add counter
      StreamSubscription? subscription;

      subscription = _controller!
          .generate(prompt: prompt, maxTokens: maxTokens, temperature: 0.7)
          .listen(
            (token) {
              fullResponse += token;
              tokenCount++; // Increment counter
              int tokensLeft = 100 - tokenCount; // Calculate remaining
              debugPrint(
                'Token $tokenCount: $token (Tokens left: $tokensLeft)',
              );
              onToken?.call(token); // Call the callback with each token
            },
            onDone: () => debugPrint(
              '✅ Recommendation generated! \nPrompt: $prompt, \nResponse: $fullResponse',
            ),
            onError: (error) => throw error,
          );

      await subscription.asFuture();
      return fullResponse.trim();
    } catch (e) {
      debugPrint('❌ Error: $e');
      return 'Failed to generate recommendation: $e';
    }
  }

  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}
