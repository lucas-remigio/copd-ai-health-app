import 'dart:math';

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
    final expectedNewGoal = _calculateNewGoal(weeklyGoal, confidence);

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

  static int _calculateNewGoal(int weeklyGoal, int confidence) {
    final rawGoal = weeklyGoal * (1 + confidence / 100);
    return (rawGoal / 10).round() * 10;
  }

  static List<TestCase> getDefaultCases({int? seed}) {
    final random = Random(seed);

    return [
      ..._buildRandomGoalAchievedCases(random, count: 24),
      ..._buildRandomHealthCases(random),
      ..._buildRandomOtherCases(random),
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

  static List<TestCase> _buildRandomHealthCases(Random random) {
    final feverGoal = _pick(random, _allowedWeeklyGoals);
    final breathlessnessGoal = _pick(random, _allowedWeeklyGoals);
    final chestPainGoal = _pick(random, _allowedWeeklyGoals);

    return [
      notAchievedHealth(
        name: 'Not Achieved - Fever (Health) - $feverGoal',
        weeklyGoal: feverGoal,
        averageSteps: _generateMissedAverage(random, feverGoal),
        reason: 'tive febre e não pude fazer exercício.',
        additionalExpectedKeywords: ['recuperação', 'saúde'],
        mustNotContain: [
          'aumentar',
          'nova meta',
          ..._randomDistractorGoals(random, actualGoal: feverGoal, count: 2),
        ],
      ),
      notAchievedHealth(
        name: 'Not Achieved - Breathlessness (Health) - $breathlessnessGoal',
        weeklyGoal: breathlessnessGoal,
        averageSteps: _generateMissedAverage(random, breathlessnessGoal),
        reason: 'senti muita falta de ar.',
        additionalExpectedKeywords: ['compreendo', 'médico'],
        mustNotContain: ['aumentar', 'reduzir'],
      ),
      notAchievedHealth(
        name: 'Not Achieved - Chest Pain (Health) - $chestPainGoal',
        weeklyGoal: chestPainGoal,
        averageSteps: _generateMissedAverage(random, chestPainGoal),
        reason: 'senti dores no peito.',
        additionalExpectedKeywords: ['saúde', 'prioridade'],
        mustNotContain: ['aumentar', 'culpa'],
      ),
    ];
  }

  static List<TestCase> _buildRandomOtherCases(Random random) {
    final rainGoal = _pick(random, _allowedWeeklyGoals);
    final workGoal = _pick(random, _allowedWeeklyGoals);
    final travelGoal = _pick(random, _allowedWeeklyGoals);

    return [
      notAchievedOther(
        name: 'Not Achieved - Rain (Other) - $rainGoal',
        weeklyGoal: rainGoal,
        averageSteps: _generateMissedAverage(random, rainGoal),
        reason: 'choveu muito e não consegui sair.',
        additionalExpectedKeywords: ['natural', 'estratégias'],
        mustNotContain: ['aumentar', 'culpa', 'preocupes'],
      ),
      notAchievedOther(
        name: 'Not Achieved - Work (Other) - $workGoal',
        weeklyGoal: workGoal,
        averageSteps: _generateMissedAverage(random, workGoal),
        reason: 'tive muito trabalho esta semana.',
        additionalExpectedKeywords: ['compreendo', 'retomar'],
        mustNotContain: ['aumentar', 'reduzir'],
      ),
      notAchievedOther(
        name: 'Not Achieved - Travel (Other) - $travelGoal',
        weeklyGoal: travelGoal,
        averageSteps: _generateMissedAverage(random, travelGoal),
        reason: 'estive de viagem.',
        additionalExpectedKeywords: ['normal', 'próxima'],
        mustNotContain: ['aumentar', 'falha'],
      ),
    ];
  }

  static int _generateAchievedAverage(Random random, int weeklyGoal) {
    return weeklyGoal + _pick(random, _allowedAchievedStepBonuses);
  }

  static int _generateMissedAverage(Random random, int weeklyGoal) {
    final validShortfalls = _allowedMissedStepShortfalls
        .where((shortfall) => weeklyGoal - shortfall > 0)
        .toList();

    return weeklyGoal - _pick(random, validShortfalls);
  }

  static List<String> _randomDistractorGoals(
    Random random, {
    required int actualGoal,
    required int count,
  }) {
    final distractors =
        _allowedWeeklyGoals
            .where((goal) => goal != actualGoal)
            .map((goal) => '$goal')
            .toList()
          ..shuffle(random);

    return distractors.take(count).toList();
  }

  static T _pick<T>(Random random, List<T> values) {
    return values[random.nextInt(values.length)];
  }
}

class TestResult {
  final TestCase testCase;
  final String response;
  final bool passed;
  final int score;
  final int maxScore;
  final List<String> issues;
  final Map<String, dynamic>? metrics;

  TestResult({
    required this.testCase,
    required this.response,
    required this.passed,
    required this.score,
    required this.maxScore,
    required this.issues,
    this.metrics,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;
}
