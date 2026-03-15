import 'package:flutter/material.dart';
import 'package:health_test_app/services/ai_llama_service.dart';
import 'package:health_test_app/services/app_state_manager.dart';
import 'package:health_test_app/services/performance_metrics_service.dart';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final AILlamaService _aiService = AILlamaService();
  final AppStateManager _appState = AppStateManager();
  String _status = 'A inicializar...';
  String _streamingTestResponse = '';
  double _progress = 0.0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _initialize() async {
    try {
      // Initialize performance metrics service
      _safeSetState(() {
        _status = 'A inicializar sistema de métricas...';
        _progress = 0.0;
      });
      await PerformanceMetricsService().initialize();

      // Initialize AI model
      await _initializeAI();

      // Then initialize app state (steps, location, etc.)
      _safeSetState(() {
        _status = 'A inicializar serviços da app...';
        _progress = 0.0;
      });

      await _appState.initialize();

      _safeSetState(() {
        _status = 'Pronto!';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(aiService: _aiService),
          ),
        );
      }
    } catch (e) {
      _safeSetState(() {
        _status = 'Falha ao inicializar: $e';
        _hasError = true;
      });
    }
  }

  Future<void> _initializeAI() async {
    try {
      _safeSetState(() {
        _status = 'A descarregar modelo de IA...';
        _progress = 0.0;
      });

      // Set progress callback
      _aiService.onDownloadProgress = (progress) {
        _safeSetState(() {
          _progress = progress;
          _status =
              'A descarregar modelo de IA... ${(progress * 100).toStringAsFixed(1)}%';
        });
      };

      await _aiService.initialize();

      _safeSetState(() {
        _status = 'A testar modelo de IA...';
        _progress = 1.0;
        _streamingTestResponse = '';
      });

      final testResponse = await _aiService.getTestResponse(
        onToken: (token) {
          _safeSetState(() {
            _streamingTestResponse += token;
            _status =
                'A testar modelo de IA...\nStreaming: $_streamingTestResponse';
          });
        },
      );

      _safeSetState(() {
        _status = 'Resposta IA:\n$testResponse';
      });

      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('AI initialization error: $e');
      rethrow;
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
                      _status = 'A tentar novamente...';
                      _progress = 0.0;
                    });
                    _initialize();
                  },
                  child: const Text('Tentar novamente'),
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
