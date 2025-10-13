import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: StepCounterScreen());
  }
}

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  int _stepCount = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _requestPermissionAndStartListening();
  }

  Future<void> _requestPermissionAndStartListening() async {
    final status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      _startListening();
    } else {
      setState(() {
        _errorMessage = 'Permission denied';
      });
    }
  }

  void _startListening() {
    Pedometer.stepCountStream.listen(
      (StepCount event) {
        setState(() {
          _stepCount = event.steps;
          _errorMessage = '';
        });
        debugPrint('Steps: ${event.steps}');
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Error: $error';
        });
        debugPrint('Pedometer error: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Step Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _requestPermissionAndStartListening,
                child: const Text('Try Again'),
              ),
            ] else ...[
              const Text('Total Steps:', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 16),
              Text(
                '$_stepCount',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
