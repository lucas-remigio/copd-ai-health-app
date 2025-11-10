import 'package:flutter/material.dart';
import '../services/unified_step_service.dart';

class StepMethodIndicator extends StatelessWidget {
  final UnifiedStepService stepService;

  const StepMethodIndicator({super.key, required this.stepService});

  @override
  Widget build(BuildContext context) {
    final info = stepService.methodInfo;

    return Card(
      color: info.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(info.icon, color: info.iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                info.description,
                style: TextStyle(fontSize: 12, color: info.textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
