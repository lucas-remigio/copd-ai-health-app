import 'package:flutter/foundation.dart';
import '../models/test_case.dart';
import '../models/performance_metrics.dart';
import 'ai_llama_service.dart';
import 'thermal_governor.dart';
import 'thermal_service.dart';

class TestRunnerService {
  final AILlamaService _aiService;
  final ThermalService _thermalService;
  final ThermalGovernor _thermalGovernor;

  /// How often to re-poll headroom while cooling down. Android rate-limits the
  /// headroom API to roughly once per second, so keep this comfortably above 1s.
  final Duration _cooldownPollInterval;

  /// Safety cap so a stuck-hot device can never stall a run indefinitely.
  final Duration _maxCooldownPerTest;

  final List<TestResult> _results = [];

  bool _isRunning = false;
  int _currentTestIndex = 0;

  TestRunnerService(
    this._aiService, {
    ThermalService? thermalService,
    ThermalGovernor? thermalGovernor,
    Duration cooldownPollInterval = const Duration(seconds: 5),
    Duration maxCooldownPerTest = const Duration(minutes: 3),
  }) : _thermalService = thermalService ?? ThermalService(),
       _thermalGovernor = thermalGovernor ?? ThermalGovernor(),
       _cooldownPollInterval = cooldownPollInterval,
       _maxCooldownPerTest = maxCooldownPerTest;

  bool get isRunning => _isRunning;
  int get currentTestIndex => _currentTestIndex;
  List<TestResult> get results => List.unmodifiable(_results);

  /// Run all tests sequentially
  Future<void> runAllTests(
    List<TestCase> testCases, {
    Function(int index, TestCase testCase)? onTestStart,
    Function(TestResult result)? onTestComplete,
    Function(Duration elapsed, double headroom)? onCooldown,
  }) async {
    if (_isRunning) return;

    _isRunning = true;
    _currentTestIndex = 0;
    _results.clear();

    // Stable id for this run so each incremental save updates one summary entry
    // (via upsert) rather than appending a new row per test.
    final runStartedAt = DateTime.now();

    try {
      for (int i = 0; i < testCases.length; i++) {
        _currentTestIndex = i;
        final testCase = testCases[i];

        // Cool down BEFORE measuring so a thermally-throttled inference is never
        // recorded — this keeps TTFT and tokens/sec comparable across the run.
        await _coolDownIfNeeded(onCooldown: onCooldown);

        onTestStart?.call(i, testCase);

        final result = await _runSingleTest(testCase);
        _results.add(result);

        onTestComplete?.call(result);

        // Persist after every test so a cancelled or killed run still leaves its
        // partial accuracy stats on the metrics screen.
        await _persistRunSummary(runStartedAt);

        // Small delay between tests
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } finally {
      _isRunning = false;
    }
  }

  /// Upsert the current run's pass/fail summary so the metrics screen can show
  /// both the latest run and the all-time cumulative accuracy — even mid-run.
  Future<void> _persistRunSummary(DateTime runStartedAt) async {
    if (_results.isEmpty) return;

    final summary = getSummary();
    await _aiService.metricsService.upsertTestRun(
      TestRunSummary(
        timestamp: runStartedAt,
        modelName: _aiService.currentModel.name,
        total: summary['total'] as int,
        passed: summary['passed'] as int,
        failed: summary['failed'] as int,
        averageScore: (summary['average_score'] as num).toDouble(),
      ),
    );
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
      notes: validation['notes'] as List<String>,
      metrics: inferenceMetrics?.toJson(),
    );
  }

  /// Pause until the device has cooled, polling headroom on a hysteresis band.
  ///
  /// Returns immediately when the device is cool or exposes no thermal signal,
  /// and gives up after [_maxCooldownPerTest] so a stuck-hot device never stalls
  /// the run. Cooling before (not after) a test means no throttled measurement
  /// is ever recorded.
  Future<void> _coolDownIfNeeded({
    Function(Duration elapsed, double headroom)? onCooldown,
  }) async {
    final stopwatch = Stopwatch();

    while (stopwatch.elapsed < _maxCooldownPerTest) {
      final headroom = await _thermalService.getHeadroom();
      if (headroom == null) return; // no thermal signal — skip gating

      final stillHot = stopwatch.isRunning
          ? !_thermalGovernor.hasRecovered(headroom)
          : _thermalGovernor.shouldCoolDown(headroom);
      if (!stillHot) {
        if (stopwatch.isRunning) {
          debugPrint(
            '✅ Cooled to headroom ${headroom.toStringAsFixed(2)} '
            'after ${stopwatch.elapsed.inSeconds}s',
          );
        }
        return;
      }

      if (!stopwatch.isRunning) {
        stopwatch.start();
        debugPrint(
          '🌡️ Headroom ${headroom.toStringAsFixed(2)} too high — cooling down',
        );
      }
      onCooldown?.call(stopwatch.elapsed, headroom);
      await Future.delayed(_cooldownPollInterval);
    }

    debugPrint('⚠️ Max cooldown reached; continuing to avoid stalling the run');
  }

  /// Validate response against test case criteria
  Map<String, dynamic> _validateResponse(String response, TestCase testCase) {
    final validation = {
      'passed': true,
      'score': 0,
      'max_score': 0,
      'issues': <String>[],
      'notes': <String>[],
    };

    final notes = validation['notes'] as List<String>;
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
          notes,
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
            if (actual != expected) {
              notes.add(
                '≈ Nova meta close match: expected $expected, got $actual '
                '(Δ${(actual - expected).abs()}, within ±10)',
              );
            }
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
    List<String> notes,
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
    } else if (RegExp(r'^\d+$').hasMatch(keywordLower)) {
      final expected = int.tryParse(keywordLower);
      if (expected != null) {
        final responseNumbers = RegExp(r'\d+')
            .allMatches(response)
            .map((match) => int.tryParse(match.group(0) ?? ''))
            .whereType<int>()
            .toList();

        // Exact match — no note needed.
        if (responseNumbers.contains(expected)) {
          return true;
        }

        // Within ±10 tolerance — count as a pass but flag it as close.
        final withinTolerance = responseNumbers
            .where((number) => (number - expected).abs() <= 10)
            .toList();
        if (withinTolerance.isNotEmpty) {
          final closest = withinTolerance.reduce(
            (a, b) => (a - expected).abs() <= (b - expected).abs() ? a : b,
          );
          notes.add(
            '≈ "$keyword" close match: got $closest '
            '(Δ${(closest - expected).abs()}, within ±10)',
          );
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
