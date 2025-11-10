import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepDetectorService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  final StreamController<int> _stepController =
      StreamController<int>.broadcast();

  int _stepCount = 0;
  double _lastMagnitude = 0;
  DateTime _lastStepTime = DateTime.now();
  bool _isStepDetectionActive = false;

  // Thresholds for step detection
  static const double _stepThreshold = 11.0; // Acceleration threshold
  static const int _minStepIntervalMs = 200; // Min time between steps (ms)
  static const int _maxStepIntervalMs = 2000; // Max time between steps (ms)

  // Shared preferences keys
  static const String _stepCountKey = 'daily_step_count';
  static const String _lastResetDateKey = 'last_reset_date';

  Stream<int> get stepCountStream => _stepController.stream;
  int get currentStepCount => _stepCount;

  /// Initialize and load saved step count
  Future<void> initialize() async {
    await _loadStepCount();
    await _checkAndResetDaily();
  }

  /// Start listening to accelerometer
  void startListening() {
    if (_isStepDetectionActive) return;

    debugPrint('🚶 Starting step detection...');
    _isStepDetectionActive = true;

    _accelerometerSubscription = accelerometerEventStream().listen(
      _onAccelerometerEvent,
      onError: (error) {
        debugPrint('❌ Accelerometer error: $error');
      },
    );
  }

  /// Stop listening to accelerometer
  void stopListening() {
    debugPrint('🛑 Stopping step detection...');
    _isStepDetectionActive = false;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  /// Handle accelerometer events
  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Calculate magnitude of acceleration vector
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    final now = DateTime.now();
    final timeSinceLastStep = now.difference(_lastStepTime).inMilliseconds;

    // Detect step: magnitude crosses threshold and enough time has passed
    if (magnitude > _stepThreshold &&
        _lastMagnitude <= _stepThreshold &&
        timeSinceLastStep > _minStepIntervalMs) {
      // Additional validation: not too much time has passed (still walking)
      if (timeSinceLastStep < _maxStepIntervalMs || _stepCount == 0) {
        _stepCount++;
        _lastStepTime = now;
        _stepController.add(_stepCount);
        _saveStepCount();

        debugPrint('👟 Step detected! Total: $_stepCount');
      }
    }

    _lastMagnitude = magnitude;
  }

  /// Load step count from storage
  Future<void> _loadStepCount() async {
    final prefs = await SharedPreferences.getInstance();
    _stepCount = prefs.getInt(_stepCountKey) ?? 0;
    debugPrint('📊 Loaded step count: $_stepCount');
    _stepController.add(_stepCount);
  }

  /// Save step count to storage
  Future<void> _saveStepCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepCountKey, _stepCount);
  }

  /// Check if we need to reset daily count (at midnight)
  Future<void> _checkAndResetDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetDate = prefs.getString(_lastResetDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

    if (lastResetDate != today) {
      debugPrint('🔄 New day detected, resetting step count');
      _stepCount = 0;
      await prefs.setString(_lastResetDateKey, today);
      await _saveStepCount();
      _stepController.add(_stepCount);
    }
  }

  /// Manually add steps (for testing)
  Future<void> addSteps(int steps) async {
    _stepCount += steps;
    if (_stepCount < 0) _stepCount = 0;
    await _saveStepCount();
    _stepController.add(_stepCount);
    debugPrint('➕ Added $steps steps. Total: $_stepCount');
  }

  /// Reset step count
  Future<void> resetSteps() async {
    _stepCount = 0;
    await _saveStepCount();
    _stepController.add(_stepCount);
    debugPrint('🔄 Step count reset');
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _stepController.close();
  }
}
