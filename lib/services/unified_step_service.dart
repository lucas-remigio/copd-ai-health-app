import 'dart:async';
import 'package:flutter/material.dart';
import 'package:health_test_app/services/health_service.dart';
import 'package:health_test_app/services/pedometer_service.dart';
import 'package:health_test_app/services/step_detector_service.dart';

enum StepDetectionMethod { healthConnect, pedometer, accelerometer, none }

class StepMethodInfo {
  final String description;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  const StepMethodInfo({
    required this.description,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}

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

  // Single method to get all UI info
  StepMethodInfo get methodInfo {
    const methodData = {
      StepDetectionMethod.healthConnect: StepMethodInfo(
        description: 'Using Google Fit / Health Connect (most accurate)',
        backgroundColor: Color(0xFFE8F5E9), // Colors.green[50]
        iconColor: Colors.green,
        textColor: Color(0xFF1B5E20), // Colors.green[900]
        icon: Icons.favorite,
      ),
      StepDetectionMethod.pedometer: StepMethodInfo(
        description: 'Using hardware step counter (accurate)',
        backgroundColor: Color(0xFFE3F2FD), // Colors.blue[50]
        iconColor: Colors.blue,
        textColor: Color(0xFF0D47A1), // Colors.blue[900]
        icon: Icons.directions_walk,
      ),
      StepDetectionMethod.accelerometer: StepMethodInfo(
        description: 'Using motion sensors (moderate accuracy)',
        backgroundColor: Color(0xFFFFF3E0), // Colors.orange[50]
        iconColor: Colors.orange,
        textColor: Color(0xFFE65100), // Colors.orange[900]
        icon: Icons.sensors,
      ),
      StepDetectionMethod.none: StepMethodInfo(
        description: 'No step detection available',
        backgroundColor: Color(0xFFFAFAFA), // Colors.grey[50]
        iconColor: Colors.grey,
        textColor: Color(0xFF212121), // Colors.grey[900]
        icon: Icons.info_outline,
      ),
    };

    return methodData[_activeMethod]!;
  }

  // ... rest of your existing methods (initialize, _tryHealthConnect, etc.)

  /// Initialize and find the best available step detection method
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    debugPrint('🔍 Searching for available step detection methods...');

    if (await _tryHealthConnect()) {
      _isInitialized = true;
      return true;
    }

    if (await _tryPedometer()) {
      _isInitialized = true;
      return true;
    }

    if (await _tryAccelerometer()) {
      _isInitialized = true;
      return true;
    }

    debugPrint('❌ No step detection method available');
    _activeMethod = StepDetectionMethod.none;
    return false;
  }

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

      final testSteps = await _healthService.getStepsToday();
      debugPrint('  ✅ Health Connect working! Current steps: $testSteps');

      _activeMethod = StepDetectionMethod.healthConnect;
      _stepCount = testSteps;
      _stepController.add(_stepCount);

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

  Future<bool> _tryPedometer() async {
    debugPrint('👟 Trying hardware pedometer...');

    try {
      final completer = Completer<bool>();
      StreamSubscription? testSubscription;

      testSubscription = _pedometerService.stepCountStream.listen(
        (stepCount) {
          debugPrint('  ✅ Pedometer working! Steps: ${stepCount.steps}');
          _activeMethod = StepDetectionMethod.pedometer;
          _stepCount = stepCount.steps;
          _stepController.add(_stepCount);

          testSubscription?.cancel();

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

  Future<bool> _tryAccelerometer() async {
    debugPrint('📊 Trying accelerometer-based detection...');

    try {
      await _stepDetector.initialize();
      _stepDetector.startListening();

      _activeMethod = StepDetectionMethod.accelerometer;
      _stepCount = _stepDetector.currentStepCount;
      _stepController.add(_stepCount);

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

  Future<void> addSteps(int steps) async {
    switch (_activeMethod) {
      case StepDetectionMethod.accelerometer:
        await _stepDetector.addSteps(steps);
        break;
      case StepDetectionMethod.healthConnect:
      case StepDetectionMethod.pedometer:
      case StepDetectionMethod.none:
        _stepCount += steps;
        if (_stepCount < 0) _stepCount = 0;
        _stepController.add(_stepCount);
        debugPrint('➕ Added $steps steps (manual). Total: $_stepCount');
        break;
    }
  }

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

  void pause() {
    debugPrint('⏸️ Pausing step detection');
    if (_activeMethod == StepDetectionMethod.accelerometer) {
      _stepDetector.stopListening();
    }
  }

  void resume() {
    debugPrint('▶️ Resuming step detection');
    if (_activeMethod == StepDetectionMethod.accelerometer) {
      _stepDetector.startListening();
    }
  }

  void dispose() {
    debugPrint('🗑️ Disposing step detection service');
    _currentSubscription?.cancel();
    _stepDetector.dispose();
    _stepController.close();
    _isInitialized = false;
  }
}
