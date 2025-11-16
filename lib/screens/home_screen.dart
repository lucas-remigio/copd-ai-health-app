import 'package:flutter/material.dart';
import 'package:health_test_app/services/ai_llama_service.dart';
import 'steps_screen.dart';
import 'places_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final AILlamaService aiService;

  const HomeScreen({super.key, required this.aiService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      StepsScreen(aiService: widget.aiService),
      PlacesScreen(aiService: widget.aiService),
      ChatScreen(aiService: widget.aiService),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
