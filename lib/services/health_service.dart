import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

  /// Extract a numeric value from health package value wrappers.
  ///
  /// Newer versions may return wrapper objects (for example
  /// NumericHealthValue) instead of raw num values.
  int _extractStepsValue(dynamic rawValue) {
    if (rawValue is num) return rawValue.toInt();

    // Handle wrapped values exposed by the plugin (e.g. NumericHealthValue).
    try {
      final dynamic value = (rawValue as dynamic).numericValue;
      if (value is num) return value.toInt();
    } catch (_) {
      // Fall through to string-based extraction below.
    }

    // Last-resort fallback: parse first numeric token from string output.
    final text = rawValue.toString();
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(text);
    if (match != null) {
      final parsed = double.tryParse(match.group(0)!);
      if (parsed != null) return parsed.toInt();
    }

    return 0;
  }

  /// Check if Health Connect is available
  Future<bool> isHealthConnectAvailable() async {
    try {
      final available = _health.isDataTypeAvailable(HealthDataType.STEPS);
      debugPrint('Health Connect available: $available');
      return available;
    } catch (e) {
      debugPrint('Error checking Health Connect availability: $e');
      return false;
    }
  }

  /// Request permissions to read step data
  Future<bool> requestPermissions() async {
    debugPrint('🔍 Checking Health Connect availability...');

    // Check if Health Connect is available first
    final available = await isHealthConnectAvailable();
    if (!available) {
      debugPrint('❌ Health Connect not available on this device');
      return false;
    }

    debugPrint('✅ Health Connect is available');
    debugPrint('📋 Requesting permissions...');

    final types = [HealthDataType.STEPS];
    final permissions = [HealthDataAccess.READ];

    try {
      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      debugPrint('Health permissions granted: $granted');

      // Additional check: verify we can actually read data
      if (granted) {
        final hasPermissions = await _health.hasPermissions(
          types,
          permissions: permissions,
        );
        debugPrint('Verified permissions: $hasPermissions');
        return hasPermissions ?? false;
      }

      return granted;
    } catch (e) {
      debugPrint('❌ Error requesting health permissions: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('Exception details: ${e.toString()}');
      }
      return false;
    }
  }

  /// Get step count for today
  Future<int> getStepsToday() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    debugPrint('📊 Fetching steps from $midnight to $now');

    try {
      final healthData = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      debugPrint('📦 Received ${healthData.length} data points');

      int totalSteps = 0;
      for (var data in healthData) {
        if (data.type == HealthDataType.STEPS) {
          final value = _extractStepsValue(data.value);
          debugPrint(
            '  Step raw type: ${data.value.runtimeType}, parsed: $value, at ${data.dateFrom}',
          );
          debugPrint('  Step entry: $value steps at ${data.dateFrom}');
          totalSteps += value;
        }
      }

      debugPrint('✅ Total steps today: $totalSteps');
      return totalSteps;
    } catch (e) {
      debugPrint('❌ Error fetching steps: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return 0;
    }
  }

  /// Get average daily steps for the last [days] days (including today).
  Future<int> getAverageDailySteps({int days = 7}) async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    debugPrint('📈 Fetching average daily steps from $start to $now');

    try {
      final healthData = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      debugPrint('📦 Average window received ${healthData.length} data points');

      final Map<DateTime, int> dayTotals = {};
      for (final data in healthData) {
        if (data.type != HealthDataType.STEPS) continue;

        final dayKey = DateTime(
          data.dateFrom.year,
          data.dateFrom.month,
          data.dateFrom.day,
        );
        final value = _extractStepsValue(data.value);
        dayTotals[dayKey] = (dayTotals[dayKey] ?? 0) + value;
      }

      if (dayTotals.isEmpty) {
        debugPrint('ℹ️ No step data found for average window');
        return 0;
      }

      final total = dayTotals.values.fold<int>(0, (sum, value) => sum + value);
      final average = (total / days).round();

      debugPrint('✅ Average daily steps ($days days): $average');
      return average;
    } catch (e) {
      debugPrint('❌ Error fetching average daily steps: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return 0;
    }
  }

  /// Get daily steps for the last 7 days (including today)
  Future<Map<DateTime, int>> getDailyStepsLast7Days() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

    debugPrint('📊 Fetching daily steps from $start to $now');

    try {
      final healthData = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      final Map<DateTime, int> dayTotals = {};
      
      // Initialize with 0 for all 7 days
      for (int i = 0; i < 7; i++) {
        final day = start.add(Duration(days: i));
        final dayKey = DateTime(day.year, day.month, day.day);
        dayTotals[dayKey] = 0;
      }

      for (final data in healthData) {
        if (data.type != HealthDataType.STEPS) continue;

        final dayKey = DateTime(
          data.dateFrom.year,
          data.dateFrom.month,
          data.dateFrom.day,
        );
        
        if (dayTotals.containsKey(dayKey)) {
          final value = _extractStepsValue(data.value);
          dayTotals[dayKey] = dayTotals[dayKey]! + value;
        }
      }

      debugPrint('✅ Fetched 7-day history: ${dayTotals.length} days recorded');
      return dayTotals;
    } catch (e) {
      debugPrint('❌ Error fetching 7-day history: $e');
      return {};
    }
  }

  /// Stream step updates (polls every 10 seconds)
  Stream<int> get stepCountStream async* {
    while (true) {
      yield await getStepsToday();
      await Future.delayed(const Duration(seconds: 10));
    }
  }
}
