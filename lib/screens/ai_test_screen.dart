import 'dart:async';
import 'package:flutter/material.dart';
import '../models/test_case.dart';
import '../services/ai_llama_service.dart';
import '../services/test_runner_service.dart';
import '../services/thermal_service.dart';
import '../theme/app_theme.dart';
import '../widgets/temperature_chart.dart';

class AITestScreen extends StatefulWidget {
  final AILlamaService aiService;

  const AITestScreen({super.key, required this.aiService});

  @override
  State<AITestScreen> createState() => _AITestScreenState();
}

class _AITestScreenState extends State<AITestScreen> {
  late TestRunnerService _testRunner;
  List<TestCase> _testCases = TestCase.getDefaultCases();

  bool _isRunning = false;
  bool _cancelRequested = false;
  int _currentTestIndex = 0;
  String _currentStatus = 'Ready to run tests';

  // Live thermal readout, polled while the screen is open so the reading and the
  // graph work all the time — before, during and after a run.
  final ThermalService _thermal = ThermalService();
  static const Duration _thermalPollInterval = Duration(seconds: 5);
  static const int _maxTempSamples = 1440; // ~2h at 5s per sample
  Timer? _thermalTimer;
  double? _currentTemp;
  double? _currentHeadroom;
  final List<double> _tempSamples = [];

  @override
  void initState() {
    super.initState();
    _testRunner = TestRunnerService(widget.aiService);
    _startThermalPolling();
  }

  @override
  void dispose() {
    _thermalTimer?.cancel();
    super.dispose();
  }

  void _startThermalPolling() {
    _pollThermal(); // take a first reading immediately
    _thermalTimer = Timer.periodic(
      _thermalPollInterval,
      (_) => _pollThermal(),
    );
  }

  Future<void> _pollThermal() async {
    final temp = await _thermal.getBatteryTemperature();
    final headroom = await _thermal.getHeadroom();
    if (!mounted) return;
    setState(() {
      _currentTemp = temp;
      _currentHeadroom = headroom;
      if (temp != null) {
        _tempSamples.add(temp);
        if (_tempSamples.length > _maxTempSamples) _tempSamples.removeAt(0);
      }
    });
  }

  Future<void> _runTests() async {
    setState(() {
      _testCases = TestCase.getDefaultCases();
      _isRunning = true;
      _cancelRequested = false;
      _currentStatus = 'Starting tests...';
      _currentTestIndex = 0;
    });

    await _testRunner.runAllTests(
      _testCases,
      onTestStart: (index, testCase) {
        if (_cancelRequested) return;
        setState(() {
          _currentTestIndex = index;
          _currentStatus = 'Running: ${testCase.name}';
        });
      },
      onTestComplete: (result) {
        setState(() {
          _currentStatus = result.passed
              ? '✅ ${result.testCase.name}'
              : '❌ ${result.testCase.name}';
        });
      },
      onCooldown: (elapsed, headroom) {
        if (_cancelRequested) return;
        setState(() {
          _currentStatus =
              '🌡️ A arrefecer o dispositivo... '
              '${elapsed.inSeconds}s (headroom ${headroom.toStringAsFixed(2)})';
        });
      },
    );

    setState(() {
      _isRunning = false;
      _currentStatus = _cancelRequested
          ? '🛑 Cancelado — resultados parciais guardados'
          : 'Tests completed!';
      _cancelRequested = false;
    });
  }

  void _cancelRun() {
    setState(() {
      _cancelRequested = true;
      _currentStatus = '🛑 A cancelar... (a terminar o teste atual)';
    });
    _testRunner.cancelRun();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _testRunner.getSummary();
    final results = _testRunner.results;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Model Testing'),
        actions: [
          // Always-visible live temperature readout.
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.thermostat, size: 18, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    _currentTemp != null
                        ? '${_currentTemp!.toStringAsFixed(1)}°C'
                        : '--°C',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (results.isNotEmpty && !_isRunning)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                setState(() {
                  _testRunner.clearResults();
                  _currentStatus = 'Ready to run tests';
                });
              },
              tooltip: 'Clear results',
            ),
        ],
      ),
      body: Column(
        children: [
          // Status card
          _buildStatusCard(summary),

          const SizedBox(height: 12),

          // Live temperature readout + graph
          _buildTemperatureCard(),

          // Progress indicator
          if (_isRunning)
            LinearProgressIndicator(
              value: _testCases.isNotEmpty
                  ? (_currentTestIndex + 1) / _testCases.length
                  : 0,
            ),

          // Results list
          Expanded(
            child: results.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return _buildResultCard(results[index], index);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // While running, the button cancels the run (idempotent, disabled once a
        // cancel is already in progress); otherwise it starts a new run.
        onPressed: _isRunning
            ? (_cancelRequested ? null : _cancelRun)
            : _runTests,
        icon: _isRunning
            ? const Icon(Icons.stop)
            : const Icon(Icons.play_arrow),
        label: Text(
          _isRunning
              ? (_cancelRequested ? 'A cancelar...' : 'Cancelar')
              : 'Run Tests',
        ),
        backgroundColor: _isRunning
            ? (_cancelRequested ? Colors.grey : Colors.red)
            : AppTheme.primary,
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> summary) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isRunning
                    ? Icons.pending
                    : summary['total'] > 0
                    ? Icons.check_circle
                    : Icons.info_outline,
                color: _isRunning
                    ? Colors.orange
                    : summary['total'] > 0
                    ? Colors.green
                    : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentStatus,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (summary['total'] > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip('Total', '${summary['total']}', Colors.blue),
                const SizedBox(width: 8),
                _buildStatChip('Passed', '${summary['passed']}', Colors.green),
                const SizedBox(width: 8),
                _buildStatChip('Failed', '${summary['failed']}', Colors.red),
                const SizedBox(width: 8),
                _buildStatChip(
                  'Score',
                  '${summary['average_score'].toStringAsFixed(1)}%',
                  Colors.purple,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemperatureCard() {
    final tempText = _currentTemp != null
        ? '${_currentTemp!.toStringAsFixed(1)} °C'
        : 'N/A';
    final headroomText = _currentHeadroom != null
        ? _currentHeadroom!.toStringAsFixed(2)
        : 'N/A';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.thermostat, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Temperatura: $tempText',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'headroom $headroomText',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_tempSamples.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'A recolher dados de temperatura...',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            )
          else ...[
            TemperatureChart(samples: List<double>.from(_tempSamples)),
            const SizedBox(height: 4),
            Text(
              '${_tempSamples.length} amostras · '
              'min ${_tempSamples.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}° · '
              'max ${_tempSamples.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}°',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No tests run yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Run Tests" to start',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          Text(
            '${_testCases.length} test cases loaded',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(TestResult result, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: result.passed
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            result.passed ? Icons.check : Icons.close,
            color: result.passed ? Colors.green : Colors.red,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                result.testCase.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (result.hasCloseMatch)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '≈ close',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${result.score}/${result.maxScore} (${result.percentage.toStringAsFixed(1)}%)',
          style: TextStyle(color: result.passed ? Colors.green : Colors.red),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input
                const Text(
                  'Input:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  result.testCase.input,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // Response
                const Text(
                  'Response:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(result.response, style: const TextStyle(fontSize: 13)),

                // Issues
                if (result.issues.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Issues:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...result.issues.map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        '• $issue',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ),
                ],

                // Notes (close matches within ±10 tolerance)
                if (result.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Notes (passed within ±10 tolerance):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...result.notes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        '• $note',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ),
                ],

                // Metrics
                if (result.metrics != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Performance Metrics:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  _buildMetricsGrid(result.metrics!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> metrics) {
    final ttft = metrics['time_to_first_token_ms'] ?? 0;
    final totalTime = metrics['total_generation_time_ms'] ?? 0;
    final tokenCount = metrics['token_count'] ?? 0;
    final tokensPerSec = tokenCount / (totalTime / 1000);
    final batteryDrain = metrics['battery_drain_percent'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('TTFT', '${ttft}ms'),
              _buildMetricItem('Total', '${totalTime}ms'),
              _buildMetricItem('Tokens', '$tokenCount'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('Speed', '${tokensPerSec.toStringAsFixed(1)}/s'),
              _buildMetricItem('Battery', '$batteryDrain%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
