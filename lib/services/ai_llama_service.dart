import 'dart:async';

import 'package:health_test_app/models/ai_model.dart';
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
  AIModelConfig _currentModel; // Current model being used

  AILlamaService({AIModelConfig? model})
    : _currentModel =
          model ?? AIModelConfig.gemma3_1b; // Default to small model

  // Getter for current model info
  AIModelConfig get currentModel => _currentModel;

  Future<void> initialize({AIModelConfig? model}) async {
    // If switching models, dispose and reset
    if (model != null && model != _currentModel) {
      debugPrint('🔄 Model change detected, disposing current model');
      _controller?.dispose();
      _controller = null;
      _currentModel = model;
      _isInitialized = false;
    }

    // If already initialized with the same model, skip
    if (_isInitialized && _controller != null) {
      debugPrint('✅ ${_currentModel.name} already initialized, skipping');
      return;
    }

    debugPrint('🤖 Initializing ${_currentModel.name}...');

    _totalSizeBytes = await _getFileSize(_currentModel.url);

    await _validateCachedModel();
    await _downloadModel();
    await _verifyFileIntegrity();
    await _loadModel();

    _isInitialized = true;
    debugPrint('✅ ${_currentModel.name} ready!');
  }

  Future<void> _validateCachedModel() async {
    final modelFile = await _getModelFile();
    if (!await modelFile.exists()) return;

    final fileSize = await modelFile.length();
    final sizeMB = (fileSize / 1024 / 1024).toStringAsFixed(1);
    final expectedMB = (_totalSizeBytes! / 1024 / 1024).toStringAsFixed(1);

    debugPrint(
      '📁 Found cached ${_currentModel.name}: $sizeMB MB (expected: $expectedMB MB)',
    );

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
    if (await modelFile.exists()) return;

    debugPrint('📥 Downloading ${_currentModel.name}...');
    _lastLogTime = DateTime.now();

    final request = http.Request('GET', Uri.parse(_currentModel.url));
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Download failed: ${response.statusCode}');
    }

    final sink = modelFile.openWrite();
    int downloadedBytes = 0;

    try {
      await for (var chunk in response.stream) {
        downloadedBytes += chunk.length;
        sink.add(chunk);

        final progress = downloadedBytes / _totalSizeBytes!;
        onDownloadProgress?.call(progress);
        _logProgress(progress);
      }

      await sink.flush();
      await sink.close();

      debugPrint('✅ ${_currentModel.name} download complete');
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
      return _currentModel.fallbackSizeBytes;
    } catch (e) {
      debugPrint('⚠️ Could not get file size: $e, using fallback');
      return _currentModel.fallbackSizeBytes;
    }
  }

  void _logProgress(double progress) {
    final now = DateTime.now();
    if (_lastLogTime == null || now.difference(_lastLogTime!).inSeconds >= 5) {
      final downloadedMB = (progress * _totalSizeBytes! / 1024 / 1024)
          .toStringAsFixed(1);
      final totalMB = (_totalSizeBytes! / 1024 / 1024).toStringAsFixed(1);
      debugPrint(
        '📊 ${_currentModel.name}: $downloadedMB / $totalMB MB (${(progress * 100).toStringAsFixed(1)}%)',
      );
      _lastLogTime = now;
    }
  }

  Future<void> _loadModel() async {
    debugPrint('🔧 Loading ${_currentModel.name}...');

    final modelPath = (await _getModelFile()).path;
    debugPrint('📍 Model path: $modelPath');

    try {
      // If controller exists and model is already loaded, dispose it first
      if (_controller != null) {
        debugPrint('⚠️ Disposing existing controller before loading new model');
        _controller?.dispose();
        _controller = null;
      }

      _controller = LlamaController();
      await _controller!.loadModel(
        modelPath: modelPath,
        threads: 4,
        contextSize: 2048,
      );

      debugPrint('✅ ${_currentModel.name} loaded successfully');
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
      '📦 ${_currentModel.name} file size: ${(size / 1024 / 1024).toStringAsFixed(2)} MB',
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
    return File('${appDir.path}/${_currentModel.fileName}');
  }

  // Method to switch models
  Future<void> switchModel(AIModelConfig newModel) async {
    debugPrint('🔄 Switching from ${_currentModel.name} to ${newModel.name}');

    // Dispose current model
    _controller?.dispose();
    _isInitialized = false;

    // Initialize new model
    await initialize(model: newModel);
  }

  // Method to delete a specific model file
  Future<void> deleteModelFile(AIModelConfig model) async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/${model.fileName}');

    if (await file.exists()) {
      await file.delete();
      debugPrint('🗑️ Deleted ${model.name}');
    }
  }

  // Method to check if model is downloaded
  Future<bool> isModelDownloaded(AIModelConfig model) async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/${model.fileName}');
    return await file.exists();
  }

  // In ai_llama_service.dart
  Future<String> getTestResponse({TokenCallback? onToken}) async {
    if (!_isInitialized) await initialize();
    if (_controller == null) throw Exception('Model not loaded');

    debugPrint('🎯 Testing model...');

    const prompt =
        "System: És um assistente prestável. Responde em 1 palavra e 1 emoji.\nUser: Diz olá\nAssistant:";

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
      return 'Teste falhou: $e';
    }
  }

  String _buildHealthRecommendationPrompt(
    int steps,
    int goal,
    List<String> formattedPlaces,
  ) {
    final neededSteps = goal - steps > 0 ? goal - steps : 0;
    return """
      System: És um assistente de saúde amigável. Com base nos passos atuais do utilizador, objetivo diário e locais próximos (com distâncias em passos), sugere UM local específico para caminhar hoje. 
      Escolhe o local com o MAIOR número de passos entre os locais próximos para maximizar o progresso em direção ao objetivo, sem exceder. 
      Calcula quantos passos faltam para atingir o objetivo e explica como caminhar até este local ajuda a aproximar-se. 
      Mantém a tua resposta concisa, motivadora e com menos de 100 palavras.

      User: Caminhei $steps passos até agora hoje. O meu objetivo diário é $goal passos, por isso preciso de $neededSteps passos adicionais. Locais próximos: ${formattedPlaces.join(', ')}. 
      Sugere-me um local para caminhar hoje para me ajudar a atingir o meu objetivo.

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
      return 'Falha ao gerar recomendação: $e';
    }
  }

  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}
