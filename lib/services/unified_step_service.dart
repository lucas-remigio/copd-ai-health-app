import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:health_test_app/services/health_service.dart';
import 'package:health_test_app/services/pedometer_service.dart';
import 'package:health_test_app/services/step_detector_service.dart';

enum StepDetectionMethod { healthConnect, pedometer, accelerometer, none }

class UnifiedStepService {
  final _healthService = HealthService();
  final _pedometerService = PedometerService();
  final _stepDetector = StepDetectorService();

  final StreamController<int> _stepController =
      StreamController<int>.broadcast();
  StreamSubscription? _currentSubscription;

  StepDetectionMethod _activeMethod = StepDetectionMethod.none;
  int _stepCount = 0;
  bool _isInitialized = false;

  Stream<int> get stepCountStream => _stepController.stream;
  int get currentStepCount => _stepCount;
  StepDetectionMethod get activeMethod => _activeMethod;

  String get methodDescription {
    switch (_activeMethod) {
      case StepDetectionMethod.healthConnect:
        return 'Using Google Fit / Health Connect (most accurate)';
      case StepDetectionMethod.pedometer:
        return 'Using hardware step counter (accurate)';
      case StepDetectionMethod.accelerometer:
        return 'Using motion sensors (moderate accuracy)';
      case StepDetectionMethod.none:
        return 'No step detection available';
    }
  }

  /// Initialize and find the best available step detection method
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    debugPrint('🔍 Searching for available step detection methods...');

    // Try Method 1: Health Connect / Google Fit
    if (await _tryHealthConnect()) {
      _isInitialized = true;
      return true;
    }

    // Try Method 2: Hardware Pedometer
    if (await _tryPedometer()) {
      _isInitialized = true;
      return true;
    }

    // Try Method 3: Accelerometer-based detection
    if (await _tryAccelerometer()) {
      _isInitialized = true;
      return true;
    }

    debugPrint('❌ No step detection method available');
    _activeMethod = StepDetectionMethod.none;
    return false;
  }

  /// Try to use Health Connect / Google Fit
  Future<bool> _tryHealthConnect() async {
    debugPrint('📱 Trying Health Connect / Google Fit...');

    try {
      final available = await _healthService.isHealthConnectAvailable();
      if (!available) {
        debugPrint('  ❌ Health Connect not available');
        return false;
      }

      final granted = await _healthService.requestPermissions();
      if (!granted) {
        debugPrint('  ❌ Health Connect permissions denied');
        return false;
      }

      // Test if we can actually read data
      final testSteps = await _healthService.getStepsToday();
      debugPrint('  ✅ Health Connect working! Current steps: $testSteps');

      _activeMethod = StepDetectionMethod.healthConnect;
      _stepCount = testSteps;
      _stepController.add(_stepCount);

      // Start listening to updates
      _currentSubscription = _healthService.stepCountStream.listen(
        (steps) {
          _stepCount = steps;
          _stepController.add(_stepCount);
        },
        onError: (error) {
          debugPrint('Health Connect stream error: $error');
        },
      );

      return true;
    } catch (e) {
      debugPrint('  ❌ Health Connect error: $e');
      return false;
    }
  }

  /// Try to use hardware pedometer
  Future<bool> _tryPedometer() async {
    debugPrint('👟 Trying hardware pedometer...');

    try {
      // Test if pedometer is available by listening for a moment
      final completer = Completer<bool>();
      StreamSubscription? testSubscription;

      testSubscription = _pedometerService.stepCountStream.listen(
        (stepCount) {
          debugPrint('  ✅ Pedometer working! Steps: ${stepCount.steps}');
          _activeMethod = StepDetectionMethod.pedometer;
          _stepCount = stepCount.steps;
          _stepController.add(_stepCount);

          testSubscription?.cancel();

          // Start permanent subscription
          _currentSubscription = _pedometerService.stepCountStream.listen(
            (stepCount) {
              _stepCount = stepCount.steps;
              _stepController.add(_stepCount);
            },
            onError: (error) {
              debugPrint('Pedometer stream error: $error');
            },
          );

          if (!completer.isCompleted) completer.complete(true);
        },
        onError: (error) {
          debugPrint('  ❌ Pedometer error: $error');
          testSubscription?.cancel();
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      // Wait up to 2 seconds for pedometer to respond
      return await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('  ❌ Pedometer timeout');
          testSubscription?.cancel();
          return false;
        },
      );
    } catch (e) {
      debugPrint('  ❌ Pedometer exception: $e');
      return false;
    }
  }

  /// Try to use accelerometer-based detection
  Future<bool> _tryAccelerometer() async {
    debugPrint('📊 Trying accelerometer-based detection...');

    try {
      await _stepDetector.initialize();
      _stepDetector.startListening();

      _activeMethod = StepDetectionMethod.accelerometer;
      _stepCount = _stepDetector.currentStepCount;
      _stepController.add(_stepCount);

      // Listen to step detector updates
      _currentSubscription = _stepDetector.stepCountStream.listen(
        (steps) {
          _stepCount = steps;
          _stepController.add(_stepCount);
        },
        onError: (error) {
          debugPrint('Accelerometer stream error: $error');
        },
      );

      debugPrint('  ✅ Accelerometer detection started');
      return true;
    } catch (e) {
      debugPrint('  ❌ Accelerometer error: $e');
      return false;
    }
  }

  /// Manually add steps (for testing or manual entry)
  Future<void> addSteps(int steps) async {
    switch (_activeMethod) {
      case StepDetectionMethod.accelerometer:
        await _stepDetector.addSteps(steps);
        break;
      case StepDetectionMethod.healthConnect:
      case StepDetectionMethod.pedometer:
      case StepDetectionMethod.none:
        // For non-accelerometer methods, just update local count
        _stepCount += steps;
        if (_stepCount < 0) _stepCount = 0;
        _stepController.add(_stepCount);
        debugPrint('➕ Added $steps steps (manual). Total: $_stepCount');
        break;
    }
  }

  /// Reset step count
  Future<void> resetSteps() async {
    switch (_activeMethod) {
      case StepDetectionMethod.accelerometer:
        await _stepDetector.resetSteps();
        break;
      case StepDetectionMethod.healthConnect:
      case StepDetectionMethod.pedometer:
      case StepDetectionMethod.none:
        _stepCount = 0;
        _stepController.add(_stepCount);
        debugPrint('🔄 Step count reset');
        break;
    }
  }

  /// Pause step detection (for battery saving)
  void pause() {
    debugPrint('⏸️ Pausing step detection');
    if (_activeMethod == StepDetectionMethod.accelerometer) {
      _stepDetector.stopListening();
    }
  }

  /// Resume step detection
  void resume() {
    debugPrint('▶️ Resuming step detection');
    if (_activeMethod == StepDetectionMethod.accelerometer) {
      _stepDetector.startListening();
    }
  }

  /// Dispose all resources
  void dispose() {
    debugPrint('🗑️ Disposing step detection service');
    _currentSubscription?.cancel();
    _stepDetector.dispose();
    _stepController.close();
    _isInitialized = false;
  }


  Color get methodColor {
    switch (_activeMethod) {
      case StepDetectionMethod.healthConnect:
        return Colors.green[50]!;
      case StepDetectionMethod.pedometer:
        return Colors.blue[50]!;
      case StepDetectionMethod.accelerometer:
        return Colors.orange[50]!;
      case StepDetectionMethod.none:
        return Colors.grey[50]!;
    }
  }

  IconData get methodIcon {
    switch (_activeMethod) {
      case StepDetectionMethod.healthConnect:
        return Icons.favorite;
      case StepDetectionMethod.pedometer:
        return Icons.directions_walk;
      case StepDetectionMethod.accelerometer:
        return Icons.sensors;
      case StepDetectionMethod.none:
        return Icons.info_outline;
    }
  }

  Color get methodIconColor {
    switch (_activeMethod) {
      case StepDetectionMethod.healthConnect:
        return Colors.green;
      case StepDetectionMethod.pedometer:
        return Colors.blue;
      case StepDetectionMethod.accelerometer:
        return Colors.orange;
      case StepDetectionMethod.none:
        return Colors.grey;
    }
  }

  Color get methodTextColor {
    switch (_activeMethod) {
      case StepDetectionMethod.healthConnect:
        return Colors.green[900]!;
      case StepDetectionMethod.pedometer:
        return Colors.blue[900]!;
      case StepDetectionMethod.accelerometer:
        return Colors.orange[900]!;
      case StepDetectionMethod.none:
        return Colors.grey[900]!;
    }
  }
}
