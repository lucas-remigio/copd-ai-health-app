class PerformanceMetrics {
  final DateTime timestamp;
  final String modelName;

  // Latency metrics (in milliseconds)
  final int timeToFirstToken; // TTFT - critical for UX
  final double averageTokenLatency; // ms per token
  final int totalGenerationTime; // Total time for complete response
  final int tokenCount; // Number of tokens generated

  // Battery metrics
  final int batteryLevelBefore; // 0-100
  final int batteryLevelAfter; // 0-100
  final int batteryDrain; // Percentage consumed
  final double batteryDrainRate; // % per second

  // Context information
  final int promptTokens; // Estimated prompt size
  final String messageType; // 'questionnaire', 'chat', 'test'

  PerformanceMetrics({
    required this.timestamp,
    required this.modelName,
    required this.timeToFirstToken,
    required this.averageTokenLatency,
    required this.totalGenerationTime,
    required this.tokenCount,
    required this.batteryLevelBefore,
    required this.batteryLevelAfter,
    required this.batteryDrain,
    required this.batteryDrainRate,
    required this.promptTokens,
    required this.messageType,
  });

  // Convert to JSON for export
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'model_name': modelName,
    'time_to_first_token_ms': timeToFirstToken,
    'average_token_latency_ms': averageTokenLatency,
    'total_generation_time_ms': totalGenerationTime,
    'token_count': tokenCount,
    'tokens_per_second': tokenCount / (totalGenerationTime / 1000),
    'battery_level_before': batteryLevelBefore,
    'battery_level_after': batteryLevelAfter,
    'battery_drain_percent': batteryDrain,
    'battery_drain_rate_percent_per_sec': batteryDrainRate,
    'prompt_tokens': promptTokens,
    'message_type': messageType,
  };

  // Human-readable summary
  String getSummary() {
    return '''
📊 Performance Metrics
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Model: $modelName
Time: ${timestamp.toString().split('.')[0]}

⚡ LATENCY:
  • Time to First Token: ${timeToFirstToken}ms
  • Avg Token Latency: ${averageTokenLatency.toStringAsFixed(2)}ms
  • Total Generation: ${totalGenerationTime}ms
  • Tokens Generated: $tokenCount
  • Speed: ${(tokenCount / (totalGenerationTime / 1000)).toStringAsFixed(2)} tokens/sec

🔋 BATTERY:
  • Before: $batteryLevelBefore%
  • After: $batteryLevelAfter%
  • Drain: $batteryDrain%
  • Drain Rate: ${batteryDrainRate.toStringAsFixed(4)}%/sec
  
📝 CONTEXT:
  • Prompt Tokens: ~$promptTokens
  • Message Type: $messageType
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ''';
  }

  // Calculate statistics from multiple metrics
  static Map<String, dynamic> calculateStats(List<PerformanceMetrics> metrics) {
    if (metrics.isEmpty) return {};

    final ttfts = metrics.map((m) => m.timeToFirstToken).toList();
    final avgLatencies = metrics.map((m) => m.averageTokenLatency).toList();
    final totalTimes = metrics.map((m) => m.totalGenerationTime).toList();
    final drains = metrics.map((m) => m.batteryDrain).toList();
    final speeds = metrics
        .map((m) => m.tokenCount / (m.totalGenerationTime / 1000))
        .toList();

    return {
      'total_inferences': metrics.length,
      'model': metrics.first.modelName,

      // Latency statistics
      'ttft_avg_ms': _average(ttfts),
      'ttft_min_ms': ttfts.reduce((a, b) => a < b ? a : b),
      'ttft_max_ms': ttfts.reduce((a, b) => a > b ? a : b),
      'ttft_std_ms': _standardDeviation(ttfts),

      'token_latency_avg_ms': _average(avgLatencies),
      'token_latency_min_ms': avgLatencies.reduce((a, b) => a < b ? a : b),
      'token_latency_max_ms': avgLatencies.reduce((a, b) => a > b ? a : b),

      'total_time_avg_ms': _average(totalTimes),
      'total_time_min_ms': totalTimes.reduce((a, b) => a < b ? a : b),
      'total_time_max_ms': totalTimes.reduce((a, b) => a > b ? a : b),

      'speed_avg_tokens_per_sec': _average(speeds),
      'speed_min_tokens_per_sec': speeds.reduce((a, b) => a < b ? a : b),
      'speed_max_tokens_per_sec': speeds.reduce((a, b) => a > b ? a : b),

      // Battery statistics
      'battery_drain_avg_percent': _average(drains),
      'battery_drain_min_percent': drains.reduce((a, b) => a < b ? a : b),
      'battery_drain_max_percent': drains.reduce((a, b) => a > b ? a : b),
      'battery_drain_total_percent': drains.reduce((a, b) => a + b),

      // Data range
      'first_timestamp': metrics.first.timestamp.toIso8601String(),
      'last_timestamp': metrics.last.timestamp.toIso8601String(),
    };
  }

  static double _average(List<num> values) {
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double _standardDeviation(List<num> values) {
    final avg = _average(values);
    final variance =
        values.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) /
        values.length;
    return variance;
  }
}
