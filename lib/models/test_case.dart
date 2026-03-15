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

  static List<TestCase> getDefaultCases() {
    return [
      // === WORKFLOW 1: Goal Achieved ===
      TestCase.goalAchieved(
        name: 'Goal Achieved - Low Confidence',
        weeklyGoal: 5000,
        averageSteps: 5300,
        confidence: 3,
        additionalExpectedKeywords: ['meta'],
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - Medium Confidence',
        weeklyGoal: 7000,
        averageSteps: 7500,
        confidence: 6,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - High Confidence',
        weeklyGoal: 8000,
        averageSteps: 9000,
        confidence: 9,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - Edge Case (Small)',
        weeklyGoal: 3000,
        averageSteps: 3200,
        confidence: 5,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - Confidence 1',
        weeklyGoal: 6000,
        averageSteps: 6200,
        confidence: 1,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - Confidence 2',
        weeklyGoal: 5000,
        averageSteps: 5400,
        confidence: 2,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - Confidence 4',
        weeklyGoal: 7500,
        averageSteps: 7800,
        confidence: 4,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - Confidence 5',
        weeklyGoal: 4000,
        averageSteps: 4300,
        confidence: 5,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - Confidence 7',
        weeklyGoal: 9000,
        averageSteps: 9500,
        confidence: 7,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - Confidence 8',
        weeklyGoal: 6500,
        averageSteps: 7000,
        confidence: 8,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - Confidence 10',
        weeklyGoal: 10000,
        averageSteps: 11000,
        confidence: 10,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - Large Goal',
        weeklyGoal: 12000,
        averageSteps: 12500,
        confidence: 3,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - Odd Goal',
        weeklyGoal: 5500,
        averageSteps: 5800,
        confidence: 6,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - 3500 Steps Confidence 2',
        weeklyGoal: 3500,
        averageSteps: 3650,
        confidence: 2,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - 4500 Steps Confidence 4',
        weeklyGoal: 4500,
        averageSteps: 4700,
        confidence: 4,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - 8500 Steps Confidence 3',
        weeklyGoal: 8500,
        averageSteps: 8900,
        confidence: 3,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - 9500 Steps Confidence 7',
        weeklyGoal: 9500,
        averageSteps: 10200,
        confidence: 7,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - 10500 Steps Confidence 5',
        weeklyGoal: 10500,
        averageSteps: 11000,
        confidence: 5,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - 3000 Steps Confidence 6',
        weeklyGoal: 3000,
        averageSteps: 3200,
        confidence: 6,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - 3500 Steps Confidence 9',
        weeklyGoal: 3500,
        averageSteps: 3800,
        confidence: 9,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - 4500 Steps Confidence 10',
        weeklyGoal: 4500,
        averageSteps: 4950,
        confidence: 10,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - 5500 Steps Confidence 3',
        weeklyGoal: 5500,
        averageSteps: 5700,
        confidence: 3,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - 7500 Steps Confidence 2',
        weeklyGoal: 7500,
        averageSteps: 7850,
        confidence: 2,
      ),
      TestCase.goalAchieved(
        name: 'Goal Achieved - 9500 Steps Confidence 4',
        weeklyGoal: 9500,
        averageSteps: 9950,
        confidence: 4,
      ),
      TestCase.notAchievedHealth(
        name: 'Not Achieved - Fever (Health)',
        weeklyGoal: 6000,
        averageSteps: 4200,
        reason: 'tive febre e não pude fazer exercício.',
        additionalExpectedKeywords: ['recuperação', 'saúde'],
        mustNotContain: ['aumentar', 'nova meta', '7000', '5000'],
      ),
      TestCase.notAchievedHealth(
        name: 'Not Achieved - Breathlessness (Health)',
        weeklyGoal: 7000,
        averageSteps: 5500,
        reason: 'senti muita falta de ar.',
        additionalExpectedKeywords: ['compreendo', 'médico'],
        mustNotContain: ['aumentar', 'reduzir'],
      ),
      TestCase.notAchievedHealth(
        name: 'Not Achieved - Chest Pain (Health)',
        weeklyGoal: 8000,
        averageSteps: 6000,
        reason: 'senti dores no peito.',
        additionalExpectedKeywords: ['saúde', 'prioridade'],
        mustNotContain: ['aumentar', 'culpa'],
      ),

      // === WORKFLOW 3: Goal Not Achieved - Other ===
      TestCase.notAchievedOther(
        name: 'Not Achieved - Rain (Other)',
        weeklyGoal: 5000,
        averageSteps: 4300,
        reason: 'choveu muito e não consegui sair.',
        additionalExpectedKeywords: ['natural', 'estratégias'],
        mustNotContain: ['aumentar', 'culpa', 'preocupes'],
      ),
      TestCase.notAchievedOther(
        name: 'Not Achieved - Work (Other)',
        weeklyGoal: 6000,
        averageSteps: 4800,
        reason: 'tive muito trabalho esta semana.',
        additionalExpectedKeywords: ['compreendo', 'retomar'],
        mustNotContain: ['aumentar', 'reduzir'],
      ),
      TestCase.notAchievedOther(
        name: 'Not Achieved - Travel (Other)',
        weeklyGoal: 10000,
        averageSteps: 8500,
        reason: 'estive de viagem.',
        additionalExpectedKeywords: ['normal', 'próxima'],
        mustNotContain: ['aumentar', 'falha'],
      ),
    ];
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
