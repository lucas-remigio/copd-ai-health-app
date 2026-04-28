import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:copd_ai_health_app/services/ai_llama_service.dart';
import 'package:copd_ai_health_app/services/app_state_manager.dart';
import 'steps_screen.dart';
import 'places_screen.dart';
import 'chat_screen.dart';
import 'performance_metrics_screen.dart';
import 'ai_interactions_screen.dart';
import 'ai_test_screen.dart';

class HomeScreen extends StatefulWidget {
  final AILlamaService aiService;

  const HomeScreen({super.key, required this.aiService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AppStateManager _appState = AppStateManager();
  StreamSubscription? _chatUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _chatUpdateSubscription = _appState.chatUpdateStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _chatUpdateSubscription?.cancel();
    super.dispose();
  }

  List<Widget> _getScreens() {
    return [
      StepsScreen(aiService: widget.aiService, scaffoldKey: _scaffoldKey),
      PlacesScreen(aiService: widget.aiService, scaffoldKey: _scaffoldKey),
      ChatScreen(aiService: widget.aiService, scaffoldKey: _scaffoldKey),
    ];
  }

  void _showNextAvailableDialog(DateTime nextDate) {
    final dateStr = DateFormat('dd/MM/yyyy').format(nextDate);
    final timeStr = DateFormat('HH:mm').format(nextDate);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Questionário Indisponível'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('O questionário semanal já foi concluído.'),
            const SizedBox(height: 16),
            Text(
              'Próxima disponibilidade:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            Text('$dateStr às $timeStr'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isChatAvailable = _appState.isQuestionnaireDue();

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'COPD AI Health',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Assistente de Saúde',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico de IA'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AIInteractionsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Métricas de Performance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PerformanceMetricsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Testar Modelo AI'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AITestScreen(aiService: widget.aiService),
                  ),
                );
              },
            ),
            if (kDebugMode) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'DEBUG',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.red),
                title: const Text(
                  'Reset Questionário',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _appState.resetQuestionnaire();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Questionário resetado!')),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
      body: _getScreens()[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // If trying to go to Chat (index 2) but it's not due
            if (index == 2 && !isChatAvailable) {
              // Only allow if we are ALREADY on the chat screen (reading)
              if (_currentIndex != 2) {
                _showNextAvailableDialog(_appState.getNextQuestionnaireDate());
                return;
              }
            }
            setState(() => _currentIndex = index);
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk),
              label: 'Passos',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.place), label: 'Locais'),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: isChatAvailable,
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: isChatAvailable ? null : Colors.grey.shade400,
                ),
              ),
              label: 'Chat',
            ),
          ],
          selectedItemColor: _currentIndex == 2 && !isChatAvailable 
              ? Colors.grey.shade600 
              : null,
          unselectedItemColor: !isChatAvailable ? Colors.grey.shade400 : null,
        ),
      ),
    );
  }
}
