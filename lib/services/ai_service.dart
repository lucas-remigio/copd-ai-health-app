import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class AIService {
  Llama? _llama;
  bool _isInitialized = false;
  bool _isLoading = false;

  Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;

    _isLoading = true;
    debugPrint('🤖 Initializing AI model...');

    try {
      final modelPath = await _getModelPath();
      debugPrint('📁 Model path: $modelPath');

      // Create model params
      final modelParams = ModelParams()
        ..nGpuLayers =
            0 // CPU only
        ..useMemorymap = true
        ..useMemoryLock = false;

      // Create context params
      final contextParams = ContextParams()
        ..nCtx = 2048
        ..nBatch = 512
        ..nThreads = 4
        ..nThreadsBatch = 4
        ..nPredict = 150;

      // Create sampler params
      final samplerParams = SamplerParams()
        ..temp = 0.7
        ..topK = 40
        ..topP = 0.9;

      // Create Llama instance
      _llama = Llama(
        modelPath,
        modelParams,
        contextParams,
        samplerParams,
        false, // verbose
      );

      _isInitialized = true;
      debugPrint('✅ AI model loaded successfully!');
    } catch (e) {
      debugPrint('❌ Error loading model: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<String> _getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelFile = File('${appDir.path}/gemma-3n-finetuned-Q4_K_M.gguf');

    // Copy model from assets to app directory if not exists
    if (!await modelFile.exists()) {
      debugPrint('📦 Copying model from assets (this may take a minute)...');
      final data = await rootBundle.load(
        'assets/models/gemma-3n-finetuned-Q4_K_M.gguf',
      );
      await modelFile.writeAsBytes(data.buffer.asUint8List());
      debugPrint('✅ Model copied to app directory');
    } else {
      debugPrint('✅ Model already exists in app directory');
    }

    return modelFile.path;
  }

  Future<String> getWalkRecommendation({
    required int currentSteps,
    required int goalSteps,
    required List<String> nearbyPlaces,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final remainingSteps = goalSteps - currentSteps;
    final placesText = nearbyPlaces.take(5).join(', ');

    // Use Gemma chat format
    final prompt =
        '''<start_of_turn>user
I have walked $currentSteps steps today. My goal is $goalSteps steps.
I still need to walk $remainingSteps steps.
Nearby attractions: $placesText

Suggest which place I should walk to and why. Keep it brief and friendly.<end_of_turn>
<start_of_turn>model
''';

    debugPrint('🎯 Generating response...');

    try {
      // Set the prompt
      _llama!.setPrompt(prompt);

      // Generate text using the stream
      final buffer = StringBuffer();
      await for (final text in _llama!.generateText()) {
        buffer.write(text);
      }

      final response = buffer.toString().trim();
      debugPrint('✅ Response generated');
      return response;
    } catch (e) {
      debugPrint('❌ Error generating response: $e');
      return 'Sorry, I couldn\'t generate a recommendation. Please try again.';
    }
  }

  void dispose() {
    _llama?.dispose();
    _isInitialized = false;
  }
}
