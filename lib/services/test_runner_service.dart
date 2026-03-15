import 'package:flutter/foundation.dart';
import '../models/test_case.dart';
import '../models/performance_metrics.dart';
import 'ai_llama_service.dart';

class TestRunnerService {
  final AILlamaService _aiService;
  final List<TestResult> _results = [];

  bool _isRunning = false;
  int _currentTestIndex = 0;

  TestRunnerService(this._aiService);

  bool get isRunning => _isRunning;
  int get currentTestIndex => _currentTestIndex;
  List<TestResult> get results => List.unmodifiable(_results);

  /// Run all tests sequentially
  Future<void> runAllTests(
    List<TestCase> testCases, {
    Function(int index, TestCase testCase)? onTestStart,
    Function(TestResult result)? onTestComplete,
  }) async {
    if (_isRunning) return;

    _isRunning = true;
    _currentTestIndex = 0;
    _results.clear();

    try {
      for (int i = 0; i < testCases.length; i++) {
        _currentTestIndex = i;
        final testCase = testCases[i];

        onTestStart?.call(i, testCase);

        final result = await _runSingleTest(testCase);
        _results.add(result);

        onTestComplete?.call(result);

        // Small delay between tests
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } finally {
      _isRunning = false;
    }
  }

  /// Run a single test case
  Future<TestResult> _runSingleTest(TestCase testCase) async {
    debugPrint('🧪 Running test: ${testCase.name}');

    // Record metrics before from service
    final metricsBefore = _aiService.metricsService.allMetrics.length;

    // Generate response
    final response = await _aiService.sendDirectMessage(testCase.input);

    // Get the metrics for this inference
    final metricsAfter = _aiService.metricsService.allMetrics.length;
    PerformanceMetrics? inferenceMetrics;
    if (metricsAfter > metricsBefore) {
      inferenceMetrics = _aiService.metricsService.allMetrics.last;
    }

    // Validate response
    final validation = _validateResponse(response, testCase);

    return TestResult(
      testCase: testCase,
      response: response,
      passed: validation['passed'] as bool,
      score: validation['score'] as int,
      maxScore: validation['max_score'] as int,
      issues: validation['issues'] as List<String>,
      metrics: inferenceMetrics?.toJson(),
    );
  }

  /// Validate response against test case criteria
  Map<String, dynamic> _validateResponse(String response, TestCase testCase) {
    final validation = {
      'passed': true,
      'score': 0,
      'max_score': 0,
      'issues': <String>[],
    };

    final responseLower = response.toLowerCase();

    // 1. Check expected keywords (each worth 1 point)
    if (testCase.expectedKeywords.isNotEmpty) {
      for (final keyword in testCase.expectedKeywords) {
        validation['max_score'] = (validation['max_score'] as int) + 1;
        if (_matchesExpectedKeyword(
          response,
          responseLower,
          keyword,
          testCase,
        )) {
          validation['score'] = (validation['score'] as int) + 1;
        } else {
          (validation['issues'] as List<String>).add(
            "Missing keyword: '$keyword'",
          );
        }
      }
    }

    // 2. Check must NOT contain (critical - fails if present)
    if (testCase.mustNotContain.isNotEmpty) {
      for (final keyword in testCase.mustNotContain) {
        if (responseLower.contains(keyword.toLowerCase())) {
          validation['passed'] = false;
          (validation['issues'] as List<String>).add(
            "❌ CRITICAL: Contains forbidden word: '$keyword'",
          );
        }
      }
    }

    // 3. Check calculation presence (for achieved goals)
    if (testCase.mustCalculate) {
      validation['max_score'] = (validation['max_score'] as int) + 2;
      final hasCalculation =
          response.contains('×') ||
          response.contains('*') ||
          response.contains('=') ||
          responseLower.contains('cálculo');

      if (hasCalculation) {
        validation['score'] = (validation['score'] as int) + 2;
      } else {
        (validation['issues'] as List<String>).add(
          'Missing explicit calculation',
        );
      }

      // 4. CRITICAL: Verify the NEW GOAL is EXACTLY correct (worth 3 points)
      if (testCase.expectedNewGoal != null) {
        validation['max_score'] = (validation['max_score'] as int) + 3;
        final expected = testCase.expectedNewGoal!;

        // Look for "Nova meta: XXXX passos" pattern
        final regex = RegExp(r'Nova meta:\s*(\d+)\s*passos');
        final match = regex.firstMatch(response);

        if (match != null) {
          final actual = int.tryParse(match.group(1) ?? '');
          if (actual != null && (actual - expected).abs() <= 10) {
            validation['score'] = (validation['score'] as int) + 3;
          } else {
            validation['passed'] = false;
            (validation['issues'] as List<String>).add(
              '❌ CRITICAL: Wrong calculation! Expected $expected, got $actual',
            );
          }
        } else {
          (validation['issues'] as List<String>).add(
            "Missing 'Nova meta: X passos' format",
          );
        }
      }
    }

    // 4. Check if maintains goal (for not achieved)
    if (!testCase.mustCalculate) {
      validation['max_score'] = (validation['max_score'] as int) + 1;
      if (_containsAny(responseLower, const [
        'manter',
        'mantém',
        'mantenha',
        'mantenhas',
        'mant',
      ])) {
        validation['score'] = (validation['score'] as int) + 1;
      } else {
        (validation['issues'] as List<String>).add(
          'Should recommend MAINTAINING current goal',
        );
      }
    }

    // Calculate percentage and final pass/fail
    final maxScore = validation['max_score'] as int;
    final score = validation['score'] as int;
    final percentage = maxScore > 0 ? (score / maxScore) * 100 : 0;

    if (percentage < 60 || !(validation['passed'] as bool)) {
      validation['passed'] = false;
    }

    return validation;
  }

  bool _matchesExpectedKeyword(
    String response,
    String responseLower,
    String keyword,
    TestCase testCase,
  ) {
    final keywordLower = keyword.toLowerCase();

    if (!testCase.mustCalculate) {
      if (keywordLower == 'manter') {
        return _containsAny(responseLower, const [
          'manter',
          'mantém',
          'mantenha',
          'mantenhas',
          'mant',
        ]);
      }

      if (keywordLower == 'médico') {
        return _containsAny(responseLower, const [
          'médico',
          'ajuda',
          'profissional',
          'saúde',
        ]);
      }

      if (const [
        'compreendo',
        'natural',
        'estratégias',
        'retomar',
        'próxima',
      ].contains(keywordLower)) {
        final root = keywordLower.length > 5
            ? keywordLower.substring(0, 5)
            : keywordLower.substring(
                0,
                keywordLower.length >= 3 ? 3 : keywordLower.length,
              );
        return responseLower.contains(root);
      }
    } else if (RegExp(r'^\d+4').hasMatch(keywordLower) ||
        RegExp(r'^\d+$').hasMatch(keywordLower)) {
      final expected = int.tryParse(keywordLower);
      if (expected != null) {
        final responseNumbers = RegExp(r'\d+')
            .allMatches(response)
            .map((match) => int.tryParse(match.group(0) ?? ''))
            .whereType<int>();

        if (responseNumbers.any((number) => (number - expected).abs() <= 10)) {
          return true;
        }
      }
    }

    return responseLower.contains(keywordLower);
  }

  bool _containsAny(String text, List<String> candidates) {
    return candidates.any(text.contains);
  }

  /// Get summary statistics
  Map<String, dynamic> getSummary() {
    if (_results.isEmpty) {
      return {'total': 0, 'passed': 0, 'failed': 0, 'average_score': 0.0};
    }

    final passed = _results.where((r) => r.passed).length;
    final avgScore =
        _results.map((r) => r.percentage).reduce((a, b) => a + b) /
        _results.length;

    return {
      'total': _results.length,
      'passed': passed,
      'failed': _results.length - passed,
      'average_score': avgScore,
    };
  }

  void clearResults() {
    _results.clear();
    _currentTestIndex = 0;
  }
}
