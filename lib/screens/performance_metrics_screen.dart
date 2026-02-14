import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/performance_metrics_service.dart';
import '../theme/app_theme.dart';

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

  Widget _buildRecentMetricsList(List metrics) {
    final recentMetrics = metrics.reversed.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 Recent Inferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...recentMetrics.map((metric) => _buildMetricItem(metric)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(dynamic metric) {
    final tokensPerSec =
        metric.tokenCount / (metric.totalGenerationTime / 1000);

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
                      color: tokensPerSec > 5 ? Colors.green : Colors.orange,
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
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
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
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
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
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
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
    final summary =
        '''
Performance Metrics Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Model: ${stats['model']}
Total Inferences: ${stats['total_inferences']}

⚡ LATENCY:
• Avg TTFT: ${stats['ttft_avg_ms']?.toStringAsFixed(0)}ms
• Avg Token Latency: ${stats['token_latency_avg_ms']?.toStringAsFixed(2)}ms
• Avg Speed: ${stats['speed_avg_tokens_per_sec']?.toStringAsFixed(2)} tokens/sec

🔋 BATTERY:
• Avg Drain: ${stats['battery_drain_avg_percent']?.toStringAsFixed(2)}%
• Total Drain: ${stats['battery_drain_total_percent']?.toStringAsFixed(1)}%

Generated by Health Test App
    ''';

    Share.share(summary);
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
