import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:copd_ai_health_app/services/ai_llama_service.dart';
import 'package:copd_ai_health_app/services/app_state_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/error_view.dart';
import 'dart:math' as math;

class StepsScreen extends StatefulWidget {
  final AILlamaService aiService;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const StepsScreen({super.key, required this.aiService, this.scaffoldKey});

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
  Map<DateTime, int>? _weeklyHistory;

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

    _loadHistory();

    await _stepCountSubscription?.cancel();
    _stepCountSubscription = _appState.stepService.stepCountStream.listen((
      steps,
    ) {
      if (!mounted) return;
      setState(() => _stepCount = steps);
      // Refresh history occasionally
      if (steps % 100 == 0) _loadHistory();
    }, onError: (error) => debugPrint('Step detection error: $error'));

    await _stepGoalSubscription?.cancel();
    _stepGoalSubscription = _appState.stepGoalStream.listen((goal) {
      if (!mounted) return;
      setState(() => _stepGoal = goal);
    });
  }

  Future<void> _loadHistory() async {
    final history = await _appState.stepService.getDailyStepsLast7Days();
    if (mounted) {
      setState(() => _weeklyHistory = history);
    }
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

    int? averageSteps;
    if (_weeklyHistory != null && _weeklyHistory!.isNotEmpty) {
      final total = _weeklyHistory!.values.fold(0, (sum, val) => sum + val);
      averageSteps = (total / _weeklyHistory!.length).round();
    }

    return Scaffold(
      appBar: AppBar(
        leading: widget.scaffoldKey != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => widget.scaffoldKey!.currentState?.openDrawer(),
              )
            : null,
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
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            // Weekly Circles at the top (has its own horizontal padding)
            _buildWeeklyCircles(),
            const SizedBox(height: 32),

            // All other content with horizontal margin
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              progress >= 1.0
                                  ? AppTheme.success
                                  : AppTheme.primary,
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

                  // Weekly Average card
                  if (averageSteps != null)
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
                                  'Média Diária (7 dias)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$averageSteps passos',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.assessment_outlined,
                                color: Colors.blue,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (averageSteps != null) const SizedBox(height: 16),

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
          ],
        ),
      ),
    );
  }

  Color _getStepColor(double progress) {
    if (progress >= 1.0) return AppTheme.success;
    if (progress >= 0.7) return AppTheme.primary;
    if (progress >= 0.4) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Widget _buildWeeklyCircles() {
    if (_weeklyHistory == null || _weeklyHistory!.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = _weeklyHistory!.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key)); // Chronological (Oldest -> Today)

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // Start at Today (last child)
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: entries.map((entry) {
          final dayName = DateFormat('E', 'pt_PT').format(entry.key).substring(0, 1).toUpperCase();
          final dateNum = DateFormat('dd').format(entry.key);
          final isToday = entry.key.day == DateTime.now().day;
          final dayProgress = (entry.value / _stepGoal).clamp(0.01, 1.0);
          final goalReached = entry.value >= _stepGoal;
          final circleColor = _getStepColor(dayProgress);

          return GestureDetector(
            onTap: () {
              final fullDate = DateFormat('EEEE, d MMMM', 'pt_PT').format(entry.key);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$fullDate: ${entry.value} passos'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? AppTheme.primary : AppTheme.textTertiary,
                    ),
                  ),
                  Text(
                    dateNum,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 4.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.surfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        CircularProgressIndicator(
                          value: dayProgress,
                          strokeWidth: 4.5,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(circleColor),
                        ),
                        if (goalReached)
                          Icon(Icons.check, size: 18, color: circleColor)
                        else if (isToday)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: circleColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.value > 0 
                      ? '${(entry.value / 1000).toStringAsFixed(1)}k'
                      : '0',
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday ? AppTheme.textPrimary : AppTheme.textTertiary,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
