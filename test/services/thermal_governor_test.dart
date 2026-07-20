import 'package:copd_ai_health_app/services/thermal_governor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThermalGovernor', () {
    final governor = ThermalGovernor(runCeiling: 0.7, resumeFloor: 0.5);

    group('shouldCoolDown', () {
      test('is true once headroom reaches the run ceiling', () {
        expect(governor.shouldCoolDown(0.7), isTrue);
        expect(governor.shouldCoolDown(0.9), isTrue);
        expect(governor.shouldCoolDown(1.2), isTrue); // past throttle threshold
      });

      test('is false while headroom is below the ceiling', () {
        expect(governor.shouldCoolDown(0.0), isFalse);
        expect(governor.shouldCoolDown(0.69), isFalse);
      });

      test('is false for an unusable reading so a run is never blocked', () {
        expect(governor.shouldCoolDown(double.nan), isFalse);
        expect(governor.shouldCoolDown(-1.0), isFalse);
      });
    });

    group('hasRecovered', () {
      test('is true once headroom drops to the resume floor', () {
        expect(governor.hasRecovered(0.5), isTrue);
        expect(governor.hasRecovered(0.2), isTrue);
      });

      test('is false while headroom is still above the floor', () {
        expect(governor.hasRecovered(0.51), isFalse);
        expect(governor.hasRecovered(0.9), isFalse);
      });

      test('is true for an unusable reading so cooldown never gets stuck', () {
        expect(governor.hasRecovered(double.nan), isTrue);
        expect(governor.hasRecovered(-1.0), isTrue);
      });
    });

    test('hysteresis band leaves a gap that avoids flapping', () {
      // Between the floor and the ceiling: not yet recovered, but also not hot
      // enough to (re)start a cooldown from cool — this is the stable band.
      const midBand = 0.6;
      expect(governor.shouldCoolDown(midBand), isFalse);
      expect(governor.hasRecovered(midBand), isFalse);
    });

    test('rejects an inverted threshold configuration', () {
      expect(
        () => ThermalGovernor(runCeiling: 0.4, resumeFloor: 0.6),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
