import 'package:flutter/material.dart';
import 'package:health_test_app/services/ai_llama_service.dart';
import 'package:health_test_app/services/unified_step_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class StepsScreen extends StatefulWidget {
  final AILlamaService aiService;

  const StepsScreen({super.key, required this.aiService});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> with WidgetsBindingObserver {
  final _stepService = UnifiedStepService();
  int _stepCount = 0;
  int _stepGoal = 10000;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stepService.pause();
    } else if (state == AppLifecycleState.resumed) {
      _stepService.resume();
    }
  }

  Future<void> _initialize() async {
    await _requestPermissions();
    if (_errorMessage.isEmpty) {
      await _initializeStepDetection();
    }
  }

  Future<void> _requestPermissions() async {
    final activityStatus = await Permission.activityRecognition.request();
    final locationStatus = await Permission.location.request();

    if (!locationStatus.isGranted) {
      setState(() => _errorMessage = 'Location permission denied');
      return;
    }

    if (!activityStatus.isGranted) {
      debugPrint('⚠️ Activity recognition not granted');
    }

    setState(() => _errorMessage = '');
  }

  Future<void> _initializeStepDetection() async {
    final success = await _stepService.initialize();

    if (!success) {
      setState(() {
        _errorMessage = 'Step detection not available on this device.';
      });
      return;
    }

    _stepCount = _stepService.currentStepCount;

    _stepService.stepCountStream.listen(
      (steps) => setState(() => _stepCount = steps),
      onError: (error) => debugPrint('Step detection error: $error'),
    );
  }

  void _showGoalDialog() {
    final controller = TextEditingController(text: _stepGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Steps',
            suffixText: 'steps',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newGoal = int.tryParse(controller.text);
              if (newGoal != null && newGoal > 0) {
                setState(() => _stepGoal = newGoal);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Steps')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initialize,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final progress = (_stepCount / _stepGoal).clamp(0.0, 1.0);
    final remaining = math.max(0, _stepGoal - _stepCount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Steps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: _showGoalDialog,
            tooltip: 'Set goal',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'add100') {
                await _stepService.addSteps(100);
              } else if (value == 'add1000') {
                await _stepService.addSteps(1000);
              } else if (value == 'reset') {
                await _stepService.resetSteps();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add100',
                child: Text('Add 100 steps'),
              ),
              const PopupMenuItem(
                value: 'add1000',
                child: Text('Add 1000 steps'),
              ),
              const PopupMenuItem(value: 'reset', child: Text('Reset steps')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Main circular progress indicator
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 20,
                      backgroundColor: AppTheme.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.surfaceVariant,
                      ),
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? AppTheme.success : AppTheme.primary,
                      ),
                    ),
                  ),
                  // Center content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _stepCount.toString(),
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'steps',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Goal card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Goal',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_stepGoal steps',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.flag,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Remaining steps card
            if (remaining > 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Steps to Go',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$remaining steps',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: AppTheme.accent,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.success.withOpacity(0.1),
                        AppTheme.success.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Goal Achieved! 🎉',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Detection method indicator
            _buildMethodIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodIndicator() {
    final info = _stepService.methodInfo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: info.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(info.icon, color: info.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
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
