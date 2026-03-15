import 'package:flutter/material.dart';

class AIRecommendationCard extends StatelessWidget {
  final String recommendation;
  final bool isLoading;
  final String streamingText;
  final VoidCallback onRefresh;

  const AIRecommendationCard({
    super.key,
    required this.recommendation,
    required this.isLoading,
    this.streamingText = '',
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'AI Walking Coach',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                if (!isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.green),
                    onPressed: onRefresh,
                    tooltip: 'Get new recommendation',
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        streamingText.isNotEmpty
                            ? streamingText
                            : 'AI is analyzing your options...',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This may take 10-30 seconds',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else if (recommendation.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No recommendation yet',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              )
            else
              Text(
                recommendation,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
          ],
        ),
      ),
    );
  }
}
