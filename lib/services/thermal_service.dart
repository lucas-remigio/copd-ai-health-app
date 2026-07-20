import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reads the device's live thermal state over a platform MethodChannel.
///
/// Prefers Android's continuous thermal headroom (0.0 cool .. 1.0 == throttling
/// threshold, and it can exceed 1.0 once throttling). Falls back to the coarse
/// 5-bucket thermal status mapped onto the same scale when headroom is
/// unavailable — e.g. an emulator, API < 30, or a rate-limited NaN reading.
///
/// Returns `null` when the platform exposes nothing usable, so callers can
/// simply skip thermal gating instead of stalling.
class ThermalService {
  ThermalService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.alentoai/thermal');

  final MethodChannel _channel;

  /// Approximate headroom for each PowerManager.THERMAL_STATUS_* value, so the
  /// coarse fallback lands on the same 0..1 scale as real headroom.
  static const Map<int, double> _statusToHeadroom = {
    0: 0.0, // NONE
    1: 0.4, // LIGHT
    2: 0.7, // MODERATE
    3: 0.9, // SEVERE
    4: 1.0, // CRITICAL
    5: 1.0, // EMERGENCY
    6: 1.0, // SHUTDOWN
  };

  /// Best-available thermal headroom, or `null` if the device reports nothing.
  Future<double?> getHeadroom() async {
    final headroom = await _readHeadroom();
    if (headroom != null && headroom.isFinite && headroom >= 0) return headroom;
    return _readStatusAsHeadroom();
  }

  /// Battery temperature in °C, or `null` if unavailable. A readable, absolute
  /// thermal signal to log per inference (complements the 0..1 headroom).
  Future<double?> getBatteryTemperature() async {
    try {
      final celsius = await _channel.invokeMethod<double>(
        'getBatteryTemperature',
      );
      if (celsius != null && celsius.isFinite && celsius > -50 && celsius < 150) {
        return celsius;
      }
      return null;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<double?> _readHeadroom() async {
    try {
      return await _channel.invokeMethod<double>('getThermalHeadroom');
    } on PlatformException catch (e) {
      debugPrint('⚠️ Thermal headroom unavailable: ${e.message}');
      return null;
    } on MissingPluginException {
      return null; // channel not registered (non-Android platforms)
    }
  }

  Future<double?> _readStatusAsHeadroom() async {
    try {
      final status = await _channel.invokeMethod<int>('getThermalStatus');
      if (status == null || status < 0) return null;
      return _statusToHeadroom[status] ?? 0.0;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
