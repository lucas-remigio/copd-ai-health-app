import 'dart:math' as math;

/// Summary of a single accuracy test-suite run (from TestRunnerService).
/// Persisted so the metrics screen can show both the latest run and an
/// all-time cumulative pass/fail tally across every run.
class TestRunSummary {
  final DateTime timestamp;
  final String modelName;
  final int total;
  final int passed;
  final int failed;
  final double averageScore; // percentage 0-100

  TestRunSummary({
    required this.timestamp,
    required this.modelName,
    required this.total,
    required this.passed,
    required this.failed,
    required this.averageScore,
  });

  /// Pass rate as a percentage (0-100).
  double get passRate => total > 0 ? (passed / total) * 100 : 0.0;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'model_name': modelName,
    'total': total,
    'passed': passed,
    'failed': failed,
    'average_score': averageScore,
    'pass_rate': passRate,
  };

  factory TestRunSummary.fromJson(Map<String, dynamic> json) => TestRunSummary(
    timestamp: DateTime.parse(json['timestamp']),
    modelName: json['model_name'] ?? 'Unknown',
    total: json['total'] ?? 0,
    passed: json['passed'] ?? 0,
    failed: json['failed'] ?? 0,
    averageScore: (json['average_score'] ?? 0).toDouble(),
  );

  /// Aggregate a list of runs into cumulative all-time totals.
  static Map<String, dynamic> cumulative(List<TestRunSummary> runs) {
    if (runs.isEmpty) {
      return {
        'runs': 0,
        'total': 0,
        'passed': 0,
        'failed': 0,
        'pass_rate': 0.0,
        'average_score': 0.0,
      };
    }

    final total = runs.fold<int>(0, (a, r) => a + r.total);
    final passed = runs.fold<int>(0, (a, r) => a + r.passed);
    final failed = runs.fold<int>(0, (a, r) => a + r.failed);
    final avgScore =
        runs.fold<double>(0.0, (a, r) => a + r.averageScore) / runs.length;

    return {
      'runs': runs.length,
      'total': total,
      'passed': passed,
      'failed': failed,
      'pass_rate': total > 0 ? (passed / total) * 100 : 0.0,
      'average_score': avgScore,
    };
  }
}

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

  // Memory metrics
  final double? modelDiskSizeMB; // Model file size on disk
  final double? appMemoryUsageMB; // App RAM usage during inference

  // Thermal snapshot taken just BEFORE generation, so a long run can be filtered
  // and plotted for thermal progression / throttling correlation.
  final double? thermalHeadroom; // 0.0 cool .. 1.0 at throttle threshold
  final double? batteryTemperatureCelsius; // device temperature proxy, °C

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
    this.modelDiskSizeMB,
    this.appMemoryUsageMB,
    this.thermalHeadroom,
    this.batteryTemperatureCelsius,
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
    'model_disk_size_mb': modelDiskSizeMB,
    'app_memory_usage_mb': appMemoryUsageMB,
    'thermal_headroom': thermalHeadroom,
    'battery_temperature_celsius': batteryTemperatureCelsius,
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

💾 MEMORY:
  • Model Disk Size: ${modelDiskSizeMB?.toStringAsFixed(1) ?? 'N/A'} MB
  • App RAM Usage: ${appMemoryUsageMB?.toStringAsFixed(1) ?? 'N/A'} MB

🌡️ THERMAL (before generation):
  • Battery Temp: ${batteryTemperatureCelsius?.toStringAsFixed(1) ?? 'N/A'} °C
  • Thermal Headroom: ${thermalHeadroom?.toStringAsFixed(2) ?? 'N/A'}

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
    final drainRates = metrics.map((m) => m.batteryDrainRate).toList();
    final speeds = metrics
        .map((m) => m.tokenCount / (m.totalGenerationTime / 1000))
        .toList();
    final tokenCounts = metrics.map((m) => m.tokenCount).toList();
    final promptTokens = metrics.map((m) => m.promptTokens).toList();

    // Optional sensors: only present on some rows, so filter nulls first.
    final rams = metrics
        .map((m) => m.appMemoryUsageMB)
        .whereType<double>()
        .toList();
    final temps = metrics
        .map((m) => m.batteryTemperatureCelsius)
        .whereType<double>()
        .toList();
    final headrooms = metrics
        .map((m) => m.thermalHeadroom)
        .whereType<double>()
        .toList();
    final diskSizes = metrics
        .map((m) => m.modelDiskSizeMB)
        .whereType<double>()
        .toList();

    // Count inferences per message type (chat / questionnaire / test).
    final messageTypeCounts = <String, int>{};
    for (final m in metrics) {
      messageTypeCounts[m.messageType] =
          (messageTypeCounts[m.messageType] ?? 0) + 1;
    }

    final first = metrics.first.timestamp;
    final last = metrics.last.timestamp;

    return {
      'total_inferences': metrics.length,
      'model': metrics.first.modelName,

      // Latency statistics (TTFT) — with spread + percentiles for the paper.
      'ttft_avg_ms': _average(ttfts),
      'ttft_median_ms': _median(ttfts),
      'ttft_min_ms': ttfts.reduce((a, b) => a < b ? a : b),
      'ttft_max_ms': ttfts.reduce((a, b) => a > b ? a : b),
      'ttft_std_ms': _standardDeviation(ttfts),
      'ttft_p90_ms': _percentile(ttfts, 90),
      'ttft_p95_ms': _percentile(ttfts, 95),
      'ttft_p99_ms': _percentile(ttfts, 99),

      'token_latency_avg_ms': _average(avgLatencies),
      'token_latency_median_ms': _median(avgLatencies),
      'token_latency_min_ms': avgLatencies.reduce((a, b) => a < b ? a : b),
      'token_latency_max_ms': avgLatencies.reduce((a, b) => a > b ? a : b),
      'token_latency_std_ms': _standardDeviation(avgLatencies),

      'total_time_avg_ms': _average(totalTimes),
      'total_time_median_ms': _median(totalTimes),
      'total_time_min_ms': totalTimes.reduce((a, b) => a < b ? a : b),
      'total_time_max_ms': totalTimes.reduce((a, b) => a > b ? a : b),
      'total_time_sum_ms': totalTimes.reduce((a, b) => a + b),

      'speed_avg_tokens_per_sec': _average(speeds),
      'speed_median_tokens_per_sec': _median(speeds),
      'speed_min_tokens_per_sec': speeds.reduce((a, b) => a < b ? a : b),
      'speed_max_tokens_per_sec': speeds.reduce((a, b) => a > b ? a : b),
      'speed_std_tokens_per_sec': _standardDeviation(speeds),

      // Token throughput
      'tokens_generated_total': tokenCounts.reduce((a, b) => a + b),
      'tokens_generated_avg': _average(tokenCounts),
      'tokens_generated_max': tokenCounts.reduce((a, b) => a > b ? a : b),
      'prompt_tokens_total': promptTokens.reduce((a, b) => a + b),
      'prompt_tokens_avg': _average(promptTokens),

      // Battery statistics
      'battery_drain_avg_percent': _average(drains),
      'battery_drain_min_percent': drains.reduce((a, b) => a < b ? a : b),
      'battery_drain_max_percent': drains.reduce((a, b) => a > b ? a : b),
      'battery_drain_total_percent': drains.reduce((a, b) => a + b),
      'battery_drain_rate_avg_percent_per_sec': _average(drainRates),
      'battery_drain_rate_max_percent_per_sec': drainRates.isEmpty
          ? 0.0
          : drainRates.reduce((a, b) => a > b ? a : b),

      // Memory statistics (only from rows that captured them)
      'app_memory_avg_mb': rams.isEmpty ? null : _average(rams),
      'app_memory_min_mb': rams.isEmpty
          ? null
          : rams.reduce((a, b) => a < b ? a : b),
      'app_memory_max_mb': rams.isEmpty
          ? null
          : rams.reduce((a, b) => a > b ? a : b),
      'model_disk_size_mb': diskSizes.isEmpty ? null : diskSizes.last,

      // Thermal statistics (snapshot taken before each generation)
      'battery_temp_avg_celsius': temps.isEmpty ? null : _average(temps),
      'battery_temp_min_celsius': temps.isEmpty
          ? null
          : temps.reduce((a, b) => a < b ? a : b),
      'battery_temp_max_celsius': temps.isEmpty
          ? null
          : temps.reduce((a, b) => a > b ? a : b),
      'thermal_headroom_avg': headrooms.isEmpty ? null : _average(headrooms),
      'thermal_headroom_max': headrooms.isEmpty
          ? null
          : headrooms.reduce((a, b) => a > b ? a : b),

      // Context breakdown
      'message_type_counts': messageTypeCounts,

      // Data range
      'first_timestamp': first.toIso8601String(),
      'last_timestamp': last.toIso8601String(),
      'collection_span_minutes': last.difference(first).inSeconds / 60.0,
    };
  }

  static double _average(List<num> values) {
    if (values.isEmpty) return 0.0;
    return values.fold<double>(0.0, (a, b) => a + b) / values.length;
  }

  static double _standardDeviation(List<num> values) {
    if (values.isEmpty) return 0.0;
    final avg = _average(values);
    final variance =
        values
            .map((v) => (v - avg) * (v - avg))
            .fold<double>(0.0, (a, b) => a + b) /
        values.length;
    return variance.isNaN ? 0.0 : math.sqrt(variance);
  }

  /// Linear-interpolated percentile [p] (0-100) of [values].
  static double _percentile(List<num> values, double p) {
    if (values.isEmpty) return 0.0;
    final sorted = [...values]..sort();
    if (sorted.length == 1) return sorted.first.toDouble();
    final rank = (p / 100) * (sorted.length - 1);
    final lower = rank.floor();
    final upper = rank.ceil();
    if (lower == upper) return sorted[lower].toDouble();
    final weight = rank - lower;
    return sorted[lower] * (1 - weight) + sorted[upper] * weight;
  }

  static double _median(List<num> values) => _percentile(values, 50);
}
