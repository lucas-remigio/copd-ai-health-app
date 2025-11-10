import 'package:flutter/material.dart';
import '../services/unified_step_service.dart';

class StepMethodIndicator extends StatelessWidget {
  final UnifiedStepService stepService;

  const StepMethodIndicator({super.key, required this.stepService});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: stepService.methodColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(stepService.methodIcon, color: stepService.methodIconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stepService.methodDescription,
                style: TextStyle(
                  fontSize: 12,
                  color: stepService.methodTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
