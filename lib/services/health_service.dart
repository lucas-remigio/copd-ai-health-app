import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

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
          final value = (data.value as num).toInt();
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

  /// Stream step updates (polls every 10 seconds)
  Stream<int> get stepCountStream async* {
    while (true) {
      yield await getStepsToday();
      await Future.delayed(const Duration(seconds: 10));
    }
  }
}
