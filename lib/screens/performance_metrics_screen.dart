import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/performance_metrics.dart';
import '../services/performance_metrics_service.dart';
import '../theme/app_theme.dart';
import 'all_inferences_screen.dart';

class PerformanceMetricsScreen extends StatefulWidget {
  const PerformanceMetricsScreen({super.key});

  @override
  State<PerformanceMetricsScreen> createState() =>
      _PerformanceMetricsScreenState();
}

class _PerformanceMetricsScreenState extends State<PerformanceMetricsScreen> {
  final _metricsService = PerformanceMetricsService();

  @override
  Widget build(BuildContext context) {
    final metrics = _metricsService.allMetrics;
    final stats = metrics.isNotEmpty ? _metricsService.getStatistics() : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Metrics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Information',
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export to CSV'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'export_json',
                child: Row(
                  children: [
                    Icon(Icons.code),
                    SizedBox(width: 8),
                    Text('Export to JSON'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Clear All Data',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'export_csv':
                  _exportCSV();
                  break;
                case 'export_json':
                  _exportJSON();
                  break;
                case 'clear':
                  _confirmClear();
                  break;
              }
            },
          ),
        ],
      ),
      body: metrics.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(metrics.length, stats),
                  const SizedBox(height: 16),
                  _buildAccuracyCard(),
                  _buildLatencyStats(stats),
                  const SizedBox(height: 16),
                  _buildBatteryStats(stats),
                  const SizedBox(height: 16),
                  _buildRecentMetricsList(metrics),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: metrics.isEmpty ? null : _shareStatistics,
        icon: const Icon(Icons.share),
        label: const Text('Share Stats'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No metrics collected yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the chat to generate AI responses',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int count, Map<String, dynamic>? stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Inferences', count.toString()),
            if (stats != null) ...[
              _buildStatRow('Model', stats['model'] ?? 'Unknown'),
              _buildStatRow(
                'Avg Speed',
                '${stats['speed_avg_tokens_per_sec']?.toStringAsFixed(2) ?? '0'} tokens/sec',
              ),
              _buildStatRow(
                'Avg TTFT',
                '${stats['ttft_avg_ms']?.toStringAsFixed(0) ?? '0'}ms',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyCard() {
    final lastRun = _metricsService.lastTestRun;
    if (lastRun == null) return const SizedBox.shrink();

    final cumulative = _metricsService.cumulativeAccuracy;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎯 Accuracy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Latest run
                Text(
                  'Latest Run • ${_formatTime(lastRun.timestamp)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAccuracyChips(
                  total: lastRun.total,
                  passed: lastRun.passed,
                  failed: lastRun.failed,
                  passRate: lastRun.passRate,
                ),
                _buildStatRow(
                  'Avg Score',
                  '${lastRun.averageScore.toStringAsFixed(1)}%',
                ),

                const Divider(height: 24),

                // Cumulative all-time
                Text(
                  'All-Time • ${cumulative['runs']} run(s)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAccuracyChips(
                  total: cumulative['total'] as int,
                  passed: cumulative['passed'] as int,
                  failed: cumulative['failed'] as int,
                  passRate: (cumulative['pass_rate'] as num).toDouble(),
                ),
                _buildStatRow(
                  'Avg Score',
                  '${(cumulative['average_score'] as num).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAccuracyChips({
    required int total,
    required int passed,
    required int failed,
    required double passRate,
  }) {
    Color rateColor;
    if (passRate >= 80) {
      rateColor = Colors.green;
    } else if (passRate >= 60) {
      rateColor = Colors.orange;
    } else {
      rateColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _buildAccuracyChip('Total', '$total', Colors.blue),
          const SizedBox(width: 8),
          _buildAccuracyChip('Passed', '$passed', Colors.green),
          const SizedBox(width: 8),
          _buildAccuracyChip('Failed', '$failed', Colors.red),
          const SizedBox(width: 8),
          _buildAccuracyChip(
            'Accuracy',
            '${passRate.toStringAsFixed(1)}%',
            rateColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatencyStats(Map<String, dynamic>? stats) {
    if (stats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ Latency Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Time to First Token',
              '${stats['ttft_avg_ms']?.toStringAsFixed(0)}ms (avg)',
            ),
            _buildStatRow(
              'TTFT Range',
              '${stats['ttft_min_ms']}ms - ${stats['ttft_max_ms']}ms',
            ),
            _buildStatRow(
              'Token Latency',
              '${stats['token_latency_avg_ms']?.toStringAsFixed(2)}ms/token',
            ),
            _buildStatRow(
              'Generation Speed',
              '${stats['speed_avg_tokens_per_sec']?.toStringAsFixed(2)} tokens/sec',
            ),
            _buildStatRow(
              'Total Time (avg)',
              '${(stats['total_time_avg_ms'] / 1000)?.toStringAsFixed(2)}s',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryStats(Map<String, dynamic>? stats) {
    if (stats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔋 Battery Consumption',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Avg Drain per Inference',
              '${stats['battery_drain_avg_percent']?.toStringAsFixed(2)}%',
            ),
            _buildStatRow(
              'Drain Range',
              '${stats['battery_drain_min_percent']?.toStringAsFixed(2)}% - ${stats['battery_drain_max_percent']?.toStringAsFixed(2)}%',
            ),
            _buildStatRow(
              'Total Battery Used',
              '${stats['battery_drain_total_percent']?.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMetricsList(List<PerformanceMetrics> metrics) {
    final recentMetrics = metrics.reversed.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📝 Recent Inferences',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _openAllInferences,
                  icon: const Icon(Icons.list, size: 18),
                  label: Text('View all (${metrics.length})'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recentMetrics.map((metric) => _buildMetricItem(metric)),
          ],
        ),
      ),
    );
  }

  Future<void> _openAllInferences() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AllInferencesScreen()),
    );
    // Deletions on that screen change the data, so refresh the summary on return.
    if (mounted) setState(() {});
  }

  Widget _buildMetricItem(PerformanceMetrics metric) {
    final tokensPerSec = metric.totalGenerationTime > 0
        ? metric.tokenCount / (metric.totalGenerationTime / 1000)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showMetricDetails(metric),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(metric.timestamp),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${tokensPerSec.toStringAsFixed(1)} tok/s',
                          style: TextStyle(
                            color: tokensPerSec > 5
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TTFT: ${metric.timeToFirstToken}ms • '
                      'Tokens: ${metric.tokenCount} • '
                      'Battery: ${metric.batteryDrain}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                tooltip: 'Delete this inference',
                onPressed: () => _deleteMetric(metric),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMetric(PerformanceMetrics metric) async {
    final removedIndex = await _metricsService.deleteMetric(metric);
    if (removedIndex < 0 || !mounted) return;
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Inference deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await _metricsService.restoreMetric(removedIndex, metric);
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showMetricDetails(dynamic metric) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Metric Details'),
        content: SingleChildScrollView(
          child: Text(
            metric.getSummary(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: metric.getSummary()));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCSV() async {
    try {
      final file = await _metricsService.exportToCSV();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: ${file.path}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => SharePlus.instance.share(
                ShareParams(files: [XFile(file.path)]),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _exportJSON() async {
    try {
      final file = await _metricsService.exportToJSON();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: ${file.path}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => SharePlus.instance.share(
                ShareParams(files: [XFile(file.path)]),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Metrics?'),
        content: const Text(
          'This will permanently delete all collected performance data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _metricsService.clearMetrics();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All metrics cleared')));
      }
    }
  }

  void _shareStatistics() {
    final stats = _metricsService.getStatistics();
    if (stats.isEmpty) {
      SharePlus.instance.share(
        ShareParams(text: 'No performance metrics collected yet.'),
      );
      return;
    }
    SharePlus.instance.share(ShareParams(text: _buildStatisticsReport(stats)));
  }

  /// Full human-readable statistics report used for the Share/email export.
  /// Kept exhaustive on purpose — this is what gets pasted into the thesis.
  String _buildStatisticsReport(Map<String, dynamic> stats) {
    // Small local helpers so a missing/optional value degrades to 'N/A'
    // instead of throwing or printing "null".
    String num0(String key) =>
        stats[key] == null ? 'N/A' : (stats[key] as num).toStringAsFixed(0);
    String num1(String key) =>
        stats[key] == null ? 'N/A' : (stats[key] as num).toStringAsFixed(1);
    String num2(String key) =>
        stats[key] == null ? 'N/A' : (stats[key] as num).toStringAsFixed(2);

    final lastRun = _metricsService.lastTestRun;
    final cumulative = _metricsService.cumulativeAccuracy;
    final accuracySection = lastRun == null
        ? ''
        : '''
🎯 ACCURACY
• Latest run: ${lastRun.passed}/${lastRun.total} passed (${lastRun.passRate.toStringAsFixed(1)}%), avg score ${lastRun.averageScore.toStringAsFixed(1)}%
• All-time (${cumulative['runs']} runs): ${cumulative['passed']}/${cumulative['total']} passed (${(cumulative['pass_rate'] as num).toStringAsFixed(1)}%)
• All-time avg score: ${(cumulative['average_score'] as num).toStringAsFixed(1)}%
''';

    final typeCounts =
        (stats['message_type_counts'] as Map?)?.cast<String, int>() ?? {};
    final typeBreakdown = typeCounts.isEmpty
        ? '• N/A'
        : (typeCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .map((e) => '• ${e.key}: ${e.value}')
              .join('\n');

    final first = DateTime.parse(stats['first_timestamp'] as String);
    final last = DateTime.parse(stats['last_timestamp'] as String);
    final spanMin = (stats['collection_span_minutes'] as num?) ?? 0;

    return '''
AlentoAI — Performance Metrics Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Model: ${stats['model']}
Total inferences: ${stats['total_inferences']}
Collection window: ${first.toString().split('.')[0]}  →  ${last.toString().split('.')[0]}
Span: ${spanMin.toStringAsFixed(1)} min
$accuracySection
⚡ TIME TO FIRST TOKEN (ms)
• Avg: ${num0('ttft_avg_ms')}   • Median: ${num0('ttft_median_ms')}   • Std: ${num0('ttft_std_ms')}
• Min: ${num0('ttft_min_ms')}   • Max: ${num0('ttft_max_ms')}
• p90: ${num0('ttft_p90_ms')}   • p95: ${num0('ttft_p95_ms')}   • p99: ${num0('ttft_p99_ms')}

⚡ TOKEN LATENCY (ms/token)
• Avg: ${num2('token_latency_avg_ms')}   • Median: ${num2('token_latency_median_ms')}   • Std: ${num2('token_latency_std_ms')}
• Min: ${num2('token_latency_min_ms')}   • Max: ${num2('token_latency_max_ms')}

⚡ GENERATION SPEED (tokens/sec)
• Avg: ${num2('speed_avg_tokens_per_sec')}   • Median: ${num2('speed_median_tokens_per_sec')}   • Std: ${num2('speed_std_tokens_per_sec')}
• Min: ${num2('speed_min_tokens_per_sec')}   • Max: ${num2('speed_max_tokens_per_sec')}

⏱️ TOTAL GENERATION TIME (ms)
• Avg: ${num0('total_time_avg_ms')}   • Median: ${num0('total_time_median_ms')}
• Min: ${num0('total_time_min_ms')}   • Max: ${num0('total_time_max_ms')}
• Sum: ${num0('total_time_sum_ms')}

🔤 TOKENS
• Generated total: ${num0('tokens_generated_total')}   • Avg/inference: ${num1('tokens_generated_avg')}   • Max: ${num0('tokens_generated_max')}
• Prompt total: ${num0('prompt_tokens_total')}   • Avg prompt: ${num1('prompt_tokens_avg')}

🔋 BATTERY
• Avg drain: ${num2('battery_drain_avg_percent')}%   • Min: ${num0('battery_drain_min_percent')}%   • Max: ${num0('battery_drain_max_percent')}%
• Total drain: ${num1('battery_drain_total_percent')}%
• Avg drain rate: ${num2('battery_drain_rate_avg_percent_per_sec')} %/s   • Max rate: ${num2('battery_drain_rate_max_percent_per_sec')} %/s

📦 MEMORY
• App RAM avg: ${num1('app_memory_avg_mb')} MB   • Min: ${num1('app_memory_min_mb')} MB   • Max: ${num1('app_memory_max_mb')} MB
• Model disk size: ${num1('model_disk_size_mb')} MB

🌡️ THERMAL (snapshot before each generation)
• Battery temp avg: ${num1('battery_temp_avg_celsius')} °C   • Min: ${num1('battery_temp_min_celsius')} °C   • Max: ${num1('battery_temp_max_celsius')} °C
• Headroom avg: ${num2('thermal_headroom_avg')}   • Max: ${num2('thermal_headroom_max')}

📝 INFERENCES BY TYPE
$typeBreakdown

Generated by AlentoAI
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Performance Metrics'),
        content: const SingleChildScrollView(
          child: Text(
            'This screen tracks AI inference performance:\n\n'
            '⚡ LATENCY METRICS:\n'
            '• Time to First Token (TTFT): How quickly the AI starts responding\n'
            '• Token Latency: Time per token generation\n'
            '• Tokens/Second: Generation speed\n\n'
            '🔋 BATTERY METRICS:\n'
            '• Battery drain during inference\n'
            '• Drain rate per second\n\n'
            '📊 USE FOR RESEARCH:\n'
            'Export data to CSV or JSON for analysis in your paper.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
