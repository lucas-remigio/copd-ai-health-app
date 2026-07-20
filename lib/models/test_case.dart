import 'dart:math';
import '../utils/step_goal_calculator.dart';

class TestCase {
  final String name;
  final String input;
  final List<String> expectedKeywords;
  final List<String> mustNotContain;
  final bool mustCalculate;
  final int? expectedNewGoal;

  TestCase({
    required this.name,
    required this.input,
    this.expectedKeywords = const [],
    this.mustNotContain = const [],
    this.mustCalculate = false,
    this.expectedNewGoal,
  });

  static const List<int> _allowedWeeklyGoals = [
    3000,
    3500,
    4000,
    4500,
    5000,
    5500,
    6000,
    6500,
    7000,
    7500,
    8000,
    8500,
    9000,
    9500,
    10000,
    10500,
    11000,
    11500,
    12000,
    12500,
  ];

  static const List<int> _allowedConfidenceLevels = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
  ];

  static const List<int> _allowedAchievedStepBonuses = [
    150,
    200,
    300,
    350,
    400,
    500,
    700,
    800,
    900,
    1000,
    1200,
    1300,
  ];

  static const List<int> _allowedMissedStepShortfalls = [
    500,
    700,
    800,
    1200,
    1500,
    1800,
    2000,
  ];

  static TestCase goalAchieved({
    required String name,
    required int weeklyGoal,
    required int averageSteps,
    required int confidence,
    List<String> additionalExpectedKeywords = const [],
    List<String> mustNotContain = const [],
  }) {
    final expectedNewGoal = StepGoalCalculator.calculateNewGoal(
      weeklyGoal,
      confidence,
    );

    return TestCase(
      name: name,
      input:
          '[CONTEXTO: Meta semanal: $weeklyGoal passos/dia. '
          'Meta atingida: Sim (média de $averageSteps passos). '
          'Confiança para aumentar: $confidence/10.]\n\n'
          'Consegui a meta esta semana e sinto-me $confidence em 10 de confiança para aumentar.',
      expectedKeywords: [
        '$weeklyGoal',
        '$confidence%',
        '$expectedNewGoal',
        'parabéns',
        ...additionalExpectedKeywords,
      ],
      mustNotContain: mustNotContain,
      mustCalculate: true,
      expectedNewGoal: expectedNewGoal,
    );
  }

  static TestCase notAchievedHealth({
    required String name,
    required int weeklyGoal,
    required int averageSteps,
    required String reason,
    List<String> additionalExpectedKeywords = const [],
    List<String> mustNotContain = const [],
  }) {
    return TestCase(
      name: name,
      input:
          '[CONTEXTO: Meta semanal: $weeklyGoal passos/dia. '
          'Meta atingida: Não (média de $averageSteps passos).]\n\n'
          'Não consegui a meta porque $reason',
      expectedKeywords: [
        'manter',
        '$weeklyGoal',
        ...additionalExpectedKeywords,
      ],
      mustNotContain: mustNotContain,
      mustCalculate: false,
    );
  }

  static TestCase notAchievedOther({
    required String name,
    required int weeklyGoal,
    required int averageSteps,
    required String reason,
    List<String> additionalExpectedKeywords = const [],
    List<String> mustNotContain = const [],
  }) {
    return TestCase(
      name: name,
      input:
          '[CONTEXTO: Meta semanal: $weeklyGoal passos/dia. '
          'Meta atingida: Não (média de $averageSteps passos).]\n\n'
          'Não consegui a meta porque $reason',
      expectedKeywords: [
        'manter',
        '$weeklyGoal',
        ...additionalExpectedKeywords,
      ],
      mustNotContain: mustNotContain,
      mustCalculate: false,
    );
  }

  /// Builds a 100-case suite: 70 goal-achieved (exercises the step-math and the
  /// exact "Nova meta" value), 15 not-achieved for health reasons and 15 for
  /// other reasons (both exercise the refuse-to-increase / maintain behavior).
  /// Pass a [seed] for a reproducible suite.
  static List<TestCase> getDefaultCases({int? seed}) {
    final random = Random(seed);

    return [
      ..._buildRandomGoalAchievedCases(random, count: 70),
      ..._buildNotAchievedCases(
        random,
        count: 15,
        label: 'Health',
        reasons: _healthReasons,
        buildCase: notAchievedHealth,
      ),
      ..._buildNotAchievedCases(
        random,
        count: 15,
        label: 'Other',
        reasons: _otherReasons,
        buildCase: notAchievedOther,
      ),
    ];
  }

  static List<TestCase> _buildRandomGoalAchievedCases(
    Random random, {
    required int count,
  }) {
    final cases = <TestCase>[];
    final confidencePool = List<int>.from(_allowedConfidenceLevels)
      ..shuffle(random);

    for (var index = 0; index < count; index++) {
      final weeklyGoal = _pick(random, _allowedWeeklyGoals);
      final confidence = index < confidencePool.length
          ? confidencePool[index]
          : _pick(random, _allowedConfidenceLevels);
      final averageSteps = _generateAchievedAverage(random, weeklyGoal);

      cases.add(
        goalAchieved(
          name:
              'Goal Achieved - Case ${index + 1} ($weeklyGoal passos, confiança $confidence)',
          weeklyGoal: weeklyGoal,
          averageSteps: averageSteps,
          confidence: confidence,
          additionalExpectedKeywords: index == 0 ? ['meta'] : const [],
        ),
      );
    }

    return cases;
  }

  /// Generates [count] not-achieved cases by cycling through a shuffled [reasons]
  /// pool, each with a randomized weekly goal and (missed) average. [buildCase]
  /// selects the health vs other variant so both share one implementation.
  static List<TestCase> _buildNotAchievedCases(
    Random random, {
    required int count,
    required String label,
    required List<_NotAchievedReason> reasons,
    required _NotAchievedBuilder buildCase,
  }) {
    final pool = List<_NotAchievedReason>.from(reasons)..shuffle(random);
    final cases = <TestCase>[];

    for (var index = 0; index < count; index++) {
      final reason = pool[index % pool.length];
      final weeklyGoal = _pick(random, _allowedWeeklyGoals);

      cases.add(
        buildCase(
          name:
              'Not Achieved - $label - Case ${index + 1} '
              '(${reason.label}, $weeklyGoal passos)',
          weeklyGoal: weeklyGoal,
          averageSteps: _generateMissedAverage(random, weeklyGoal),
          reason: reason.text,
          additionalExpectedKeywords: reason.expectedKeywords,
          mustNotContain: reason.mustNotContain,
        ),
      );
    }

    return cases;
  }

  /// Distinct COPD-relevant reasons a patient did not meet the goal for a
  /// *health* motive. The assistant must stay empathetic and never push for more
  /// activity ('aumentar' is always forbidden).
  static const List<_NotAchievedReason> _healthReasons = [
    _NotAchievedReason(
      label: 'Fever',
      text: 'tive febre e não pude fazer exercício.',
      expectedKeywords: ['recuperação', 'saúde'],
      mustNotContain: ['aumentar', 'nova meta'],
    ),
    _NotAchievedReason(
      label: 'Breathlessness',
      text: 'senti muita falta de ar.',
      expectedKeywords: ['compreendo', 'médico'],
      mustNotContain: ['aumentar', 'reduzir'],
    ),
    _NotAchievedReason(
      label: 'Chest pain',
      text: 'senti dores no peito.',
      expectedKeywords: ['saúde', 'prioridade'],
      mustNotContain: ['aumentar', 'culpa'],
    ),
    _NotAchievedReason(
      label: 'Dizziness',
      text: 'senti tonturas quando tentei caminhar.',
      expectedKeywords: ['compreendo', 'médico'],
      mustNotContain: ['aumentar', 'culpa'],
    ),
    _NotAchievedReason(
      label: 'Fatigue',
      text: 'senti um cansaço extremo durante toda a semana.',
      expectedKeywords: ['descanso', 'compreendo'],
      mustNotContain: ['aumentar', 'culpa'],
    ),
    _NotAchievedReason(
      label: 'COPD exacerbation',
      text: 'tive uma exacerbação da minha DPOC.',
      expectedKeywords: ['saúde', 'médico'],
      mustNotContain: ['aumentar', 'nova meta'],
    ),
    _NotAchievedReason(
      label: 'Respiratory infection',
      text: 'apanhei uma infeção respiratória.',
      expectedKeywords: ['recuperação', 'saúde'],
      mustNotContain: ['aumentar', 'reduzir'],
    ),
    _NotAchievedReason(
      label: 'Joint pain',
      text: 'tive muitas dores nas articulações.',
      expectedKeywords: ['compreendo', 'descanso'],
      mustNotContain: ['aumentar', 'culpa'],
    ),
    _NotAchievedReason(
      label: 'Persistent cough',
      text: 'tive uma tosse persistente e muita expetoração.',
      expectedKeywords: ['saúde', 'médico'],
      mustNotContain: ['aumentar', 'reduzir'],
    ),
    _NotAchievedReason(
      label: 'Palpitations',
      text: 'senti palpitações no coração ao esforçar-me.',
      expectedKeywords: ['médico', 'saúde'],
      mustNotContain: ['aumentar', 'culpa'],
    ),
  ];

  /// Distinct non-medical reasons the goal was missed. The assistant must
  /// normalize the setback and keep the goal, never increasing it.
  static const List<_NotAchievedReason> _otherReasons = [
    _NotAchievedReason(
      label: 'Rain',
      text: 'choveu muito e não consegui sair.',
      expectedKeywords: ['natural', 'estratégias'],
      mustNotContain: ['aumentar', 'culpa', 'preocupes'],
    ),
    _NotAchievedReason(
      label: 'Work',
      text: 'tive muito trabalho esta semana.',
      expectedKeywords: ['compreendo', 'retomar'],
      mustNotContain: ['aumentar', 'reduzir'],
    ),
    _NotAchievedReason(
      label: 'Travel',
      text: 'estive de viagem.',
      expectedKeywords: ['normal', 'próxima'],
      mustNotContain: ['aumentar', 'falha'],
    ),
    _NotAchievedReason(
      label: 'Low motivation',
      text: 'não tive motivação para caminhar.',
      expectedKeywords: ['compreendo', 'estratégias'],
      mustNotContain: ['aumentar', 'culpa'],
    ),
    _NotAchievedReason(
      label: 'Family commitments',
      text: 'tive vários compromissos familiares.',
      expectedKeywords: ['compreendo', 'retomar'],
      mustNotContain: ['aumentar', 'culpa'],
    ),
    _NotAchievedReason(
      label: 'Heat',
      text: 'esteve demasiado calor para sair à rua.',
      expectedKeywords: ['natural', 'estratégias'],
      mustNotContain: ['aumentar', 'preocupes'],
    ),
    _NotAchievedReason(
      label: 'Cold',
      text: 'esteve demasiado frio lá fora.',
      expectedKeywords: ['natural', 'próxima'],
      mustNotContain: ['aumentar', 'culpa'],
    ),
    _NotAchievedReason(
      label: 'No time',
      text: 'não tive tempo esta semana.',
      expectedKeywords: ['compreendo', 'retomar'],
      mustNotContain: ['aumentar', 'reduzir'],
    ),
    _NotAchievedReason(
      label: 'Sore feet',
      text: 'os sapatos magoavam-me os pés.',
      expectedKeywords: ['compreendo', 'estratégias'],
      mustNotContain: ['aumentar', 'culpa'],
    ),
    _NotAchievedReason(
      label: 'Low mood',
      text: 'senti-me em baixo e sem energia.',
      expectedKeywords: ['compreendo', 'próxima'],
      mustNotContain: ['aumentar', 'culpa'],
    ),
  ];

  static int _generateAchievedAverage(Random random, int weeklyGoal) {
    return weeklyGoal + _pick(random, _allowedAchievedStepBonuses);
  }

  static int _generateMissedAverage(Random random, int weeklyGoal) {
    final validShortfalls = _allowedMissedStepShortfalls
        .where((shortfall) => weeklyGoal - shortfall > 0)
        .toList();

    return weeklyGoal - _pick(random, validShortfalls);
  }

  static T _pick<T>(Random random, List<T> values) {
    return values[random.nextInt(values.length)];
  }
}

/// A single not-achieved reason template used to generate many cases.
class _NotAchievedReason {
  final String label; // short English tag for the test name
  final String text; // the patient's reason, in PT-PT
  final List<String> expectedKeywords;
  final List<String> mustNotContain;

  const _NotAchievedReason({
    required this.label,
    required this.text,
    this.expectedKeywords = const [],
    this.mustNotContain = const ['aumentar'],
  });
}

/// Shared shape of [TestCase.notAchievedHealth] and [TestCase.notAchievedOther]
/// so one generator can build either variant.
typedef _NotAchievedBuilder =
    TestCase Function({
      required String name,
      required int weeklyGoal,
      required int averageSteps,
      required String reason,
      List<String> additionalExpectedKeywords,
      List<String> mustNotContain,
    });

class TestResult {
  final TestCase testCase;
  final String response;
  final bool passed;
  final int score;
  final int maxScore;
  final List<String> issues;

  /// Non-fatal observations, e.g. a numeric value that passed within the
  /// ±10 tolerance but did not match the expected value exactly.
  final List<String> notes;
  final Map<String, dynamic>? metrics;

  TestResult({
    required this.testCase,
    required this.response,
    required this.passed,
    required this.score,
    required this.maxScore,
    required this.issues,
    this.notes = const [],
    this.metrics,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  /// True when the result passed but at least one value only matched within
  /// the ±10 tolerance (not an exact match).
  bool get hasCloseMatch => notes.isNotEmpty;
}
