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

  static List<TestCase> getDefaultCases() {
    return [
      // === WORKFLOW 1: Goal Achieved ===
      TestCase(
        name: 'Goal Achieved - Low Confidence',
        input:
            '[CONTEXTO: Meta semanal: 5000 passos/dia. '
            'Meta atingida: Sim (média de 5300 passos). '
            'Confiança para aumentar: 3/10.]\n\n'
            'Consegui a meta esta semana e sinto-me 3 em 10 de confiança para aumentar.',
        expectedKeywords: ['5000', '3%', '5150', 'parabéns', 'meta'],
        mustCalculate: true,
        expectedNewGoal: 5150,
      ),
      TestCase(
        name: 'Goal Achieved - Medium Confidence',
        input:
            '[CONTEXTO: Meta semanal: 7000 passos/dia. '
            'Meta atingida: Sim (média de 7500 passos). '
            'Confiança para aumentar: 6/10.]\n\n'
            'Consegui a meta esta semana e sinto-me 6 em 10 de confiança para aumentar.',
        expectedKeywords: ['7000', '6%', '7420', 'parabéns'],
        mustCalculate: true,
        expectedNewGoal: 7420,
      ),
      TestCase(
        name: 'Goal Achieved - High Confidence',
        input:
            '[CONTEXTO: Meta semanal: 8000 passos/dia. '
            'Meta atingida: Sim (média de 9000 passos). '
            'Confiança para aumentar: 9/10.]\n\n'
            'Consegui a meta esta semana e sinto-me 9 em 10 de confiança para aumentar.',
        expectedKeywords: ['8000', '9%', '8720', 'parabéns'],
        mustCalculate: true,
        expectedNewGoal: 8720,
      ),
      TestCase(
        name: 'Goal Achieved - Edge Case (Small)',
        input:
            '[CONTEXTO: Meta semanal: 3000 passos/dia. '
            'Meta atingida: Sim (média de 3200 passos). '
            'Confiança para aumentar: 5/10.]\n\n'
            'Consegui a meta esta semana e sinto-me 5 em 10 de confiança para aumentar.',
        expectedKeywords: ['3000', '5%', '3150', 'parabéns'],
        mustCalculate: true,
        expectedNewGoal: 3150,
      ),

      // === WORKFLOW 2: Goal Not Achieved - Health ===
      TestCase(
        name: 'Not Achieved - Fever (Health)',
        input:
            '[CONTEXTO: Meta semanal: 6000 passos/dia. '
            'Meta atingida: Não (média de 4200 passos).]\n\n'
            'Não consegui a meta porque tive febre e não pude fazer exercício.',
        expectedKeywords: ['manter', '6000', 'recuperação', 'saúde'],
        mustNotContain: ['aumentar', 'nova meta', '7000', '5000'],
        mustCalculate: false,
      ),
      TestCase(
        name: 'Not Achieved - Breathlessness (Health)',
        input:
            '[CONTEXTO: Meta semanal: 7000 passos/dia. '
            'Meta atingida: Não (média de 5500 passos).]\n\n'
            'Não consegui a meta porque senti muita falta de ar.',
        expectedKeywords: ['manter', '7000', 'compreendo', 'médico'],
        mustNotContain: ['aumentar', 'reduzir'],
        mustCalculate: false,
      ),

      // === WORKFLOW 3: Goal Not Achieved - Other ===
      TestCase(
        name: 'Not Achieved - Rain (Other)',
        input:
            '[CONTEXTO: Meta semanal: 5000 passos/dia. '
            'Meta atingida: Não (média de 4300 passos).]\n\n'
            'Não consegui a meta porque choveu muito e não consegui sair.',
        expectedKeywords: ['manter', '5000', 'natural', 'estratégias'],
        mustNotContain: ['aumentar', 'culpa', 'preocupes'],
        mustCalculate: false,
      ),
      TestCase(
        name: 'Not Achieved - Work (Other)',
        input:
            '[CONTEXTO: Meta semanal: 6000 passos/dia. '
            'Meta atingida: Não (média de 4800 passos).]\n\n'
            'Não consegui a meta porque tive muito trabalho esta semana.',
        expectedKeywords: ['manter', '6000', 'compreendo', 'retomar'],
        mustNotContain: ['aumentar', 'reduzir'],
        mustCalculate: false,
      ),
      TestCase(
        name: 'Not Achieved - Travel (Other)',
        input:
            '[CONTEXTO: Meta semanal: 10000 passos/dia. '
            'Meta atingida: Não (média de 8500 passos).]\n\n'
            'Não consegui a meta porque estive de viagem.',
        expectedKeywords: ['manter', '10000', 'normal', 'próxima'],
        mustNotContain: ['aumentar', 'falha'],
        mustCalculate: false,
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
