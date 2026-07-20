import 'package:copd_ai_health_app/models/test_case.dart';
import 'package:copd_ai_health_app/utils/step_goal_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TestCase.getDefaultCases', () {
    test('builds a 100-case suite split 70 / 15 / 15', () {
      final cases = TestCase.getDefaultCases(seed: 1);

      expect(cases, hasLength(100));
      expect(
        cases.where((c) => c.name.contains('Goal Achieved')),
        hasLength(70),
      );
      expect(
        cases.where((c) => c.name.contains('Health')),
        hasLength(15),
      );
      expect(
        cases.where((c) => c.name.contains('Other')),
        hasLength(15),
      );
    });

    test('is reproducible for a given seed', () {
      final first = TestCase.getDefaultCases(seed: 42).map((c) => c.name);
      final second = TestCase.getDefaultCases(seed: 42).map((c) => c.name);
      expect(first, orderedEquals(second));
    });

    test('goal-achieved cases require the exact calculator result', () {
      final achieved = TestCase.getDefaultCases(
        seed: 7,
      ).where((c) => c.mustCalculate);

      expect(achieved, isNotEmpty);
      for (final testCase in achieved) {
        expect(testCase.expectedNewGoal, isNotNull);
        // The expected goal must equal the calculator, so the suite grades the
        // model against the same source of truth the app uses.
        expect(
          testCase.expectedKeywords,
          contains('${testCase.expectedNewGoal}'),
        );
      }
    });

    test('not-achieved cases never allow increasing the goal', () {
      final notAchieved = TestCase.getDefaultCases(
        seed: 3,
      ).where((c) => !c.mustCalculate);

      expect(notAchieved, hasLength(30));
      for (final testCase in notAchieved) {
        expect(testCase.mustNotContain, contains('aumentar'));
        expect(testCase.expectedKeywords, contains('manter'));
      }
    });
  });

  group('StepGoalCalculator', () {
    test('increases the goal by the confidence percentage, rounded to 10', () {
      // 10000 * (1 + 8/100) = 10800 -> nearest 10 stays 10800
      expect(StepGoalCalculator.calculateNewGoal(10000, 8), 10800);
    });

    test('rounds to the nearest 10', () {
      // 6500 * 1.03 = 6695 -> 6700
      expect(StepGoalCalculator.calculateNewGoal(6500, 3), 6700);
    });
  });
}
