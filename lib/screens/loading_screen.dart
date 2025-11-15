import 'package:flutter/material.dart';
import 'package:health_test_app/services/ai_llama_service.dart';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final AILlamaService _aiService = AILlamaService();
  String _status = 'Initializing...';
  String _streamingTestResponse = ''; // New: For streaming test response
  double _progress = 0.0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    try {
      setState(() {
        _status = 'Downloading AI model...';
        _progress = 0.0;
      });

      // Set progress callback
      _aiService.onDownloadProgress = (progress) {
        setState(() {
          _progress = progress;
          _status =
              'Downloading AI model... ${(progress * 100).toStringAsFixed(1)}%';
        });
      };

      await _aiService.initialize();

      setState(() {
        _status = 'Testing AI model...';
        _progress = 1.0;
        _streamingTestResponse = ''; // Reset streaming
      });

      final testResponse = await _aiService.getTestResponse(
        onToken: (token) {
          // New: Stream tokens to UI
          setState(() {
            _streamingTestResponse += token;
            _status = 'Testing AI model...\nStreaming: $_streamingTestResponse';
          });
        },
      );

      setState(() {
        _status = 'AI Response:\n$testResponse';
      });

      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(aiService: _aiService),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Failed to initialize AI: $e';
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_hasError) ...[
                CircularProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                ),
                const SizedBox(height: 32),
                if (_progress > 0 && _progress < 1)
                  Text(
                    '${(_progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (_hasError) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _status = 'Retrying...';
                      _progress = 0.0;
                    });
                    _initializeAI();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _aiService.onDownloadProgress = null;
    super.dispose();
  }
}
