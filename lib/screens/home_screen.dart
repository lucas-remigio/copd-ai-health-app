import 'package:flutter/material.dart';
import 'package:copd_ai_health_app/services/ai_llama_service.dart';
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
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      StepsScreen(aiService: widget.aiService, scaffoldKey: _scaffoldKey),
      PlacesScreen(aiService: widget.aiService, scaffoldKey: _scaffoldKey),
      ChatScreen(aiService: widget.aiService, scaffoldKey: _scaffoldKey),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk),
              label: 'Passos',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.place), label: 'Locais'),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chat',
            ),
          ],
        ),
      ),
    );
  }
}
