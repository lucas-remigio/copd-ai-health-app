import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/performance_metrics.dart';

class PerformanceMetricsService {
  static final PerformanceMetricsService _instance =
      PerformanceMetricsService._internal();
  factory PerformanceMetricsService() => _instance;
  PerformanceMetricsService._internal();

  final Battery _battery = Battery();
  final List<PerformanceMetrics> _metrics = [];

  // Tracking state for current inference
  DateTime? _inferenceStartTime;
  DateTime? _firstTokenTime;
  int _tokenCount = 0;
  int? _batteryBefore;
  String _currentModelName = '';
  String _currentMessageType = 'chat';
  int _promptTokens = 0;
  String? _modelFilePath;

  // Settings
  bool _isEnabled = true;
  bool _autoExport = false;

  List<PerformanceMetrics> get allMetrics => List.unmodifiable(_metrics);
  bool get isEnabled => _isEnabled;

  /// Initialize the service
  Future<void> initialize() async {
    await _loadSettings();
    await _loadStoredMetrics();
    debugPrint('📊 Performance Metrics Service initialized');
    debugPrint('   Stored metrics: ${_metrics.length}');
    debugPrint('   Tracking enabled: $_isEnabled');
  }

  /// Start tracking a new inference
  Future<void> startInference({
    required String modelName,
    required String messageType,
    int promptTokens = 0,
    String? modelFilePath,
  }) async {
    if (!_isEnabled) return;

    _inferenceStartTime = DateTime.now();
    _firstTokenTime = null;
    _tokenCount = 0;
    _currentModelName = modelName;
    _currentMessageType = messageType;
    _promptTokens = promptTokens;
    _modelFilePath = modelFilePath;

    try {
      _batteryBefore = await _battery.batteryLevel;
      debugPrint('🔋 Battery before: $_batteryBefore%');
    } catch (e) {
      debugPrint('⚠️ Could not read battery level: $e');
      _batteryBefore = null;
    }
  }

  /// Record when first token is received
  void recordFirstToken() {
    if (!_isEnabled || _firstTokenTime != null) return;
    _firstTokenTime = DateTime.now();
  }

  /// Record each token generation
  void recordToken() {
    if (!_isEnabled) return;
    _tokenCount++;
  }

  /// End tracking and save metrics
  Future<PerformanceMetrics?> endInference() async {
    if (!_isEnabled || _inferenceStartTime == null) return null;

    final endTime = DateTime.now();

    // Calculate latency metrics
    final timeToFirstToken = _firstTokenTime != null
        ? _firstTokenTime!.difference(_inferenceStartTime!).inMilliseconds
        : 0;

    final totalGenerationTime = endTime
        .difference(_inferenceStartTime!)
        .inMilliseconds;

    final averageTokenLatency = _tokenCount > 0
        ? totalGenerationTime / _tokenCount
        : 0.0;

    // Calculate battery metrics
    int batteryAfter = _batteryBefore ?? 0;
    try {
      batteryAfter = await _battery.batteryLevel;
      debugPrint('🔋 Battery after: $batteryAfter%');
    } catch (e) {
      debugPrint('⚠️ Could not read battery level: $e');
    }

    final batteryDrain = _batteryBefore != null
        ? (_batteryBefore! - batteryAfter).abs()
        : 0;

    final batteryDrainRate = totalGenerationTime > 0
        ? batteryDrain / (totalGenerationTime / 1000)
        : 0.0;

    // Calculate memory metrics
    double? modelDiskSizeMB;
    double? appMemoryUsageMB;

    try {
      // Get model disk size
      if (_modelFilePath != null) {
        final modelFile = File(_modelFilePath!);
        if (await modelFile.exists()) {
          final sizeBytes = await modelFile.length();
          modelDiskSizeMB = sizeBytes / (1024 * 1024);
          debugPrint(
            '💾 Model disk size: ${modelDiskSizeMB.toStringAsFixed(1)} MB',
          );
        }
      }

      // Get app RAM usage (Resident Set Size)
      final rssBytes = ProcessInfo.currentRss;
      appMemoryUsageMB = rssBytes / (1024 * 1024);
      debugPrint('📦 App RAM usage: ${appMemoryUsageMB.toStringAsFixed(1)} MB');
    } catch (e) {
      debugPrint('⚠️ Could not collect memory metrics: $e');
    }

    // Create metrics object
    final metrics = PerformanceMetrics(
      timestamp: _inferenceStartTime!,
      modelName: _currentModelName,
      timeToFirstToken: timeToFirstToken,
      averageTokenLatency: averageTokenLatency,
      totalGenerationTime: totalGenerationTime,
      tokenCount: _tokenCount,
      batteryLevelBefore: _batteryBefore ?? 0,
      batteryLevelAfter: batteryAfter,
      batteryDrain: batteryDrain,
      batteryDrainRate: batteryDrainRate,
      modelDiskSizeMB: modelDiskSizeMB,
      appMemoryUsageMB: appMemoryUsageMB,
      promptTokens: _promptTokens,
      messageType: _currentMessageType,
    );

    _metrics.add(metrics);
    await _saveMetrics();

    if (_autoExport && _metrics.length % 10 == 0) {
      await exportToCSV();
    }

    debugPrint(metrics.getSummary());

    // Reset state
    _inferenceStartTime = null;
    _firstTokenTime = null;
    _tokenCount = 0;
    _batteryBefore = null;

    return metrics;
  }

  /// Get statistics for all metrics
  Map<String, dynamic> getStatistics() {
    return PerformanceMetrics.calculateStats(_metrics);
  }

  /// Export metrics to CSV file
  Future<File> exportToCSV() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .split('.')[0]
        .replaceAll(':', '-');
    final file = File('${directory.path}/performance_metrics_$timestamp.csv');

    final csv = StringBuffer();

    // Header
    csv.writeln(
      'timestamp,model_name,time_to_first_token_ms,average_token_latency_ms,'
      'total_generation_time_ms,token_count,tokens_per_second,'
      'battery_level_before,battery_level_after,battery_drain_percent,'
      'battery_drain_rate_percent_per_sec,model_disk_size_mb,app_memory_usage_mb,'
      'prompt_tokens,message_type',
    );

    // Data rows
    for (final metric in _metrics) {
      final tokensPerSec =
          metric.tokenCount / (metric.totalGenerationTime / 1000);
      csv.writeln(
        '${metric.timestamp.toIso8601String()},'
        '${metric.modelName},'
        '${metric.timeToFirstToken},'
        '${metric.averageTokenLatency.toStringAsFixed(2)},'
        '${metric.totalGenerationTime},'
        '${metric.tokenCount},'
        '${tokensPerSec.toStringAsFixed(2)},'
        '${metric.batteryLevelBefore},'
        '${metric.batteryLevelAfter},'
        '${metric.batteryDrain},'
        '${metric.batteryDrainRate.toStringAsFixed(6)},'
        '${metric.modelDiskSizeMB?.toStringAsFixed(2) ?? ''},'
        '${metric.appMemoryUsageMB?.toStringAsFixed(2) ?? ''},'
        '${metric.promptTokens},'
        '${metric.messageType}',
      );
    }

    await file.writeAsString(csv.toString());
    debugPrint('📊 Exported ${_metrics.length} metrics to: ${file.path}');

    return file;
  }

  /// Export metrics to JSON file
  Future<File> exportToJSON() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .split('.')[0]
        .replaceAll(':', '-');
    final file = File('${directory.path}/performance_metrics_$timestamp.json');

    final data = {
      'export_date': DateTime.now().toIso8601String(),
      'total_metrics': _metrics.length,
      'statistics': getStatistics(),
      'metrics': _metrics.map((m) => m.toJson()).toList(),
    };

    await file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
    debugPrint('📊 Exported ${_metrics.length} metrics to: ${file.path}');

    return file;
  }

  /// Clear all metrics
  Future<void> clearMetrics() async {
    _metrics.clear();
    await _saveMetrics();
    debugPrint('🗑️ Cleared all performance metrics');
  }

  /// Enable/disable tracking
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _saveSettings();
    debugPrint('📊 Performance tracking ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable/disable auto-export
  Future<void> setAutoExport(bool enabled) async {
    _autoExport = enabled;
    await _saveSettings();
    debugPrint('📤 Auto-export ${enabled ? 'enabled' : 'disabled'}');
  }

  // Private methods for persistence

  Future<void> _saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _metrics.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList('performance_metrics', jsonList);
    } catch (e) {
      debugPrint('⚠️ Error saving metrics: $e');
    }
  }

  Future<void> _loadStoredMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('performance_metrics') ?? [];

      _metrics.clear();
      for (final jsonStr in jsonList) {
        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final metric = PerformanceMetrics(
            timestamp: DateTime.parse(json['timestamp']),
            modelName: json['model_name'],
            timeToFirstToken: json['time_to_first_token_ms'],
            averageTokenLatency: json['average_token_latency_ms'].toDouble(),
            totalGenerationTime: json['total_generation_time_ms'],
            tokenCount: json['token_count'],
            batteryLevelBefore: json['battery_level_before'],
            batteryLevelAfter: json['battery_level_after'],
            batteryDrain: json['battery_drain_percent'],
            batteryDrainRate: json['battery_drain_rate_percent_per_sec']
                .toDouble(),
            modelDiskSizeMB: json['model_disk_size_mb']?.toDouble(),
            appMemoryUsageMB: json['app_memory_usage_mb']?.toDouble(),
            promptTokens: json['prompt_tokens'],
            messageType: json['message_type'],
          );
          _metrics.add(metric);
        } catch (e) {
          debugPrint('⚠️ Error parsing metric: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading metrics: $e');
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('metrics_enabled', _isEnabled);
    await prefs.setBool('metrics_auto_export', _autoExport);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('metrics_enabled') ?? true;
    _autoExport = prefs.getBool('metrics_auto_export') ?? false;
  }
}
