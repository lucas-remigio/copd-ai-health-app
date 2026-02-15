import 'package:flutter/material.dart';
import '../models/test_case.dart';
import '../services/ai_llama_service.dart';
import '../services/test_runner_service.dart';
import '../theme/app_theme.dart';

class AITestScreen extends StatefulWidget {
  final AILlamaService aiService;

  const AITestScreen({super.key, required this.aiService});

  @override
  State<AITestScreen> createState() => _AITestScreenState();
}

class _AITestScreenState extends State<AITestScreen> {
  late TestRunnerService _testRunner;
  final List<TestCase> _testCases = TestCase.getDefaultCases();

  bool _isRunning = false;
  int _currentTestIndex = 0;
  String _currentStatus = 'Ready to run tests';

  @override
  void initState() {
    super.initState();
    _testRunner = TestRunnerService(widget.aiService);
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _currentStatus = 'Starting tests...';
    });

    await _testRunner.runAllTests(
      _testCases,
      onTestStart: (index, testCase) {
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
    );

    setState(() {
      _isRunning = false;
      _currentStatus = 'Tests completed!';
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = _testRunner.getSummary();
    final results = _testRunner.results;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Model Testing'),
        actions: [
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
        onPressed: _isRunning ? null : _runTests,
        icon: _isRunning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isRunning ? 'Running...' : 'Run Tests'),
        backgroundColor: _isRunning ? Colors.grey : AppTheme.primary,
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

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
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
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            result.passed ? Icons.check : Icons.close,
            color: result.passed ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          result.testCase.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
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
