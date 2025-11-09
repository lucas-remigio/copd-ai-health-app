class AIModelConfig {
  final String name;
  final String url;
  final String fileName;
  final int fallbackSizeBytes;
  final String description;

  const AIModelConfig({
    required this.name,
    required this.url,
    required this.fileName,
    required this.fallbackSizeBytes,
    required this.description,
  });

  // Available models
  static const gemma3n = AIModelConfig(
    name: 'Gemma 3N',
    url:
        'https://huggingface.co/lucasxvr/quantized_gemma3n_finetuned_health_test/resolve/main/gemma-3n-finetuned-Q4_K_M.gguf',
    fileName: 'gemma-3n-finetuned-Q4_K_M.gguf',
    fallbackSizeBytes: 2658 * 1024 * 1024, // 2658 MB
    description: 'Large model - Best quality, slower',
  );

  static const gemma3_1b = AIModelConfig(
    name: 'Gemma 3 1B',
    url:
        'https://huggingface.co/lucasxvr/gemma-3-1b/resolve/main/gemma-3-1b-finetuned-Q4_K_M.gguf',
    fileName: 'gemma-3-1b-finetuned-Q4_K_M.gguf',
    fallbackSizeBytes: 768 * 1024 * 1024, // 768 MB
    description: 'Small model - Faster, less storage',
  );

  // List all available models
  static const availableModels = [gemma3n, gemma3_1b];
}
