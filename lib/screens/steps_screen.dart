import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health_test_app/services/ai_llama_service.dart';
import 'package:health_test_app/services/app_state_manager.dart';
import 'package:health_test_app/screens/performance_metrics_screen.dart';
import 'package:health_test_app/screens/ai_test_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/error_view.dart';
import 'dart:math' as math;

class StepsScreen extends StatefulWidget {
  final AILlamaService aiService;

  const StepsScreen({super.key, required this.aiService});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> with WidgetsBindingObserver {
  final _appState = AppStateManager();
  StreamSubscription<int>? _stepCountSubscription;
  StreamSubscription<int>? _stepGoalSubscription;
  int _stepCount = 0;
  int _stepGoal = 10000;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _stepGoalSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // Don't dispose singleton
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _appState.stepService.pause();
    } else if (state == AppLifecycleState.resumed) {
      _appState.stepService.resume();
    }
  }

  Future<void> _initialize() async {
    await _requestPermissions();
    if (_errorMessage == null) {
      await _initializeStepDetection();
    }
  }

  Future<void> _requestPermissions() async {
    final activityStatus = await Permission.activityRecognition.request();
    final locationStatus = await Permission.location.request();

    if (!mounted) return;

    if (!locationStatus.isGranted) {
      setState(() => _errorMessage = 'Location permission denied');
      return;
    }

    if (!activityStatus.isGranted) {
      debugPrint('⚠️ Activity recognition not granted');
    }

    setState(() => _errorMessage = null);
  }

  Future<void> _initializeStepDetection() async {
    // AppStateManager already initialized in main, just get current count
    if (!mounted) return;

    setState(() {
      _stepCount = _appState.stepService.currentStepCount;
      _stepGoal = _appState.stepGoal;
    });

    await _stepCountSubscription?.cancel();
    _stepCountSubscription = _appState.stepService.stepCountStream.listen((
      steps,
    ) {
      if (!mounted) return;
      setState(() => _stepCount = steps);
    }, onError: (error) => debugPrint('Step detection error: $error'));

    await _stepGoalSubscription?.cancel();
    _stepGoalSubscription = _appState.stepGoalStream.listen((goal) {
      if (!mounted) return;
      setState(() => _stepGoal = goal);
    });
  }

  void _showGoalDialog() {
    final controller = TextEditingController(text: _stepGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir Meta Diária'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Passos',
            suffixText: 'passos',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final newGoal = int.tryParse(controller.text);
              if (newGoal != null && newGoal > 0) {
                _appState.setStepGoal(newGoal);
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Passos')),
        body: ErrorView(errorMessage: _errorMessage!, onRetry: _initialize),
      );
    }

    final progress = (_stepCount / _stepGoal).clamp(0.0, 1.0);
    final remaining = math.max(0, _stepGoal - _stepCount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passos Diários'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: _showGoalDialog,
            tooltip: 'Definir meta',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'add100') {
                await _appState.stepService.addSteps(100);
              } else if (value == 'add1000') {
                await _appState.stepService.addSteps(1000);
              } else if (value == 'reset') {
                await _appState.stepService.resetSteps();
              } else if (value == 'metrics') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PerformanceMetricsScreen(),
                  ),
                );
              } else if (value == 'test') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AITestScreen(aiService: widget.aiService),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add100',
                child: Text('Adicionar 100 passos'),
              ),
              const PopupMenuItem(
                value: 'add1000',
                child: Text('Adicionar 1000 passos'),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Text('Reiniciar passos'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'metrics',
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Performance Metrics'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test',
                child: Row(
                  children: [
                    Icon(Icons.science_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('AI Model Testing'),
                  ],
                ),
              ),
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
                        'passos',
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
                          'Meta Diária',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_stepGoal passos',
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
                        color: AppTheme.primary.withValues(alpha: 0.1),
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
                            'Passos em Falta',
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
                          color: AppTheme.accent.withValues(alpha: 0.1),
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
                        AppTheme.success.withValues(alpha: 0.1),
                        AppTheme.success.withValues(alpha: 0.05),
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
                          'Meta Alcançada! 🎉',
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
    final info = _appState.stepService.methodInfo;
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
