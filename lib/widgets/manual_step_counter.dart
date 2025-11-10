import 'package:flutter/material.dart';

class ManualStepCounter extends StatelessWidget {
  final int stepCount;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ManualStepCounter({
    super.key,
    required this.stepCount,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Manual Step Counter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your device does not support automatic step tracking',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 40,
                  onPressed: onDecrement,
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text(
                      '$stepCount',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('steps'),
                  ],
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 40,
                  onPressed: onIncrement,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => {/* add 100 steps */},
                  child: const Text('+100'),
                ),
                TextButton(
                  onPressed: () => {/* add 1000 steps */},
                  child: const Text('+1000'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
