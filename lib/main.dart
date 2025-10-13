import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: StepCounterScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  int _stepCount = 0;
  Position? _currentPosition;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _requestPermissions();
    _startListening();
    _getCurrentLocation();
  }

  Future<void> _requestPermissions() async {
    final activityStatus = await Permission.activityRecognition.request();
    final locationStatus = await Permission.location.request();

    if (!activityStatus.isGranted || !locationStatus.isGranted) {
      setState(() => _errorMessage = 'Permissions denied');
    }
  }

  void _startListening() {
    Pedometer.stepCountStream.listen(_onStepCount, onError: _onError);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _currentPosition = position;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() => _errorMessage = 'Location error: $e');
      debugPrint('Location error: $e');
    }
  }

  void _onStepCount(StepCount event) {
    setState(() {
      _stepCount = event.steps;
      _errorMessage = '';
    });
  }

  void _onError(dynamic error) {
    setState(() => _errorMessage = 'Error: $error');
    debugPrint('Pedometer error: $error');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Step Counter'), centerTitle: true),
      body: Center(
        child: _errorMessage.isNotEmpty ? _buildErrorView() : _buildDataView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initialize,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Total Steps',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 16),
        Text(
          '$_stepCount',
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 48),
        if (_currentPosition != null) ...[
          const Text(
            'Current Location',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 8),
          Text(
            'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Long: ${_currentPosition!.longitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Location'),
          ),
        ],
      ],
    );
  }
}
