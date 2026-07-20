import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/performance_metrics.dart';
import '../services/performance_metrics_service.dart';
import '../theme/app_theme.dart';

/// Lists every saved inference with a trash button to delete a specific one.
/// Kept as its own screen (not the summary card) so a long history renders in a
/// lazy [ListView] instead of a giant scrolling column.
class AllInferencesScreen extends StatefulWidget {
  const AllInferencesScreen({super.key});

  @override
  State<AllInferencesScreen> createState() => _AllInferencesScreenState();
}

class _AllInferencesScreenState extends State<AllInferencesScreen> {
  final _metricsService = PerformanceMetricsService();

  @override
  Widget build(BuildContext context) {
    // Newest first, matching how people scan a log.
    final metrics = _metricsService.allMetrics.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text('All Inferences (${metrics.length})')),
      body: metrics.isEmpty
          ? const Center(child: Text('No inferences saved yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: metrics.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _buildRow(metrics[index]),
            ),
    );
  }

  Widget _buildRow(PerformanceMetrics metric) {
    final tokensPerSec = metric.totalGenerationTime > 0
        ? metric.tokenCount / (metric.totalGenerationTime / 1000)
        : 0.0;
    final temp = metric.batteryTemperatureCelsius;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () => _showDetails(metric),
        title: Row(
          children: [
            Text(
              _formatTimestamp(metric.timestamp),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Text(
              '${tokensPerSec.toStringAsFixed(1)} tok/s',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: tokensPerSec > 5 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        subtitle: Text(
          'TTFT ${metric.timeToFirstToken}ms · '
          'tokens ${metric.tokenCount} · '
          '${temp != null ? '${temp.toStringAsFixed(1)}°C · ' : ''}'
          '${metric.messageType}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
          tooltip: 'Delete this inference',
          onPressed: () => _deleteMetric(metric),
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

  void _showDetails(PerformanceMetrics metric) {
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

  String _formatTimestamp(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}
