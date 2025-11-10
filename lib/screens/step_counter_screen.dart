import 'package:flutter/material.dart';
import 'package:health_test_app/services/ai_llama_service.dart';
import 'package:health_test_app/services/unified_step_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../models/place.dart';
import '../widgets/step_counter_card.dart';
import '../widgets/location_info_card.dart';
import '../widgets/nearby_places_card.dart';
import '../widgets/places_map.dart';
import '../widgets/error_view.dart';
import '../widgets/ai_recommendation_card.dart';
import '../widgets/step_method_indicator.dart';

class StepCounterScreen extends StatefulWidget {
  final AILlamaService aiService;

  const StepCounterScreen({super.key, required this.aiService});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen>
    with WidgetsBindingObserver {
  final _locationService = LocationService();
  final _placesService = PlacesService();
  final _stepService = UnifiedStepService();

  int _stepCount = 0;
  Position? _currentPosition;
  List<Place> _nearbyPlaces = [];
  String _errorMessage = '';
  bool _isLoadingPlaces = false;
  bool _hasSearchedPlaces = false;
  String _recommendation = '';
  bool _isLoadingRecommendation = false;
  String _streamingRecommendation = '';

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
      await _loadLocation();
    }
  }

  Future<void> _requestPermissions() async {
    final activityStatus = await Permission.activityRecognition.request();
    final locationStatus = await Permission.location.request();

    debugPrint('Activity permission: ${activityStatus.toString()}');
    debugPrint('Location permission: ${locationStatus.toString()}');

    if (!locationStatus.isGranted) {
      setState(() => _errorMessage = 'Location permission denied');
      return;
    }

    if (!activityStatus.isGranted) {
      debugPrint(
        '⚠️ Activity recognition not granted, some features may be limited',
      );
    }

    setState(() => _errorMessage = '');
  }

  Future<void> _initializeStepDetection() async {
    final success = await _stepService.initialize();

    if (!success) {
      setState(() {
        _errorMessage =
            'Step detection not available on this device.\n'
            'You can still manually add steps using the menu.';
      });
      return;
    }

    _stepCount = _stepService.currentStepCount;

    _stepService.stepCountStream.listen(
      (steps) {
        setState(() {
          _stepCount = steps;
        });
      },
      onError: (error) {
        debugPrint('Step detection error: $error');
      },
    );
  }

  Future<void> _loadLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Location error: $e');
      debugPrint('Location error: $e');
    }
  }

  Future<void> _fetchNearbyPlaces() async {
    if (_currentPosition == null) {
      setState(() => _errorMessage = 'Location not available');
      return;
    }

    setState(() {
      _isLoadingPlaces = true;
      _isLoadingRecommendation = true;
    });

    try {
      final places = await _placesService.fetchNearbyPlaces(_currentPosition!);
      setState(() {
        _nearbyPlaces = places;
        _isLoadingPlaces = false;
        _hasSearchedPlaces = true;
      });

      setState(() {
        _recommendation = '';
        _streamingRecommendation = '';
      });

      final recommendation = await widget.aiService.getHealthRecommendation(
        _stepCount,
        10000,
        places,
        onToken: (token) {
          setState(() {
            _streamingRecommendation += token;
          });
        },
      );

      setState(() {
        _recommendation = recommendation;
        _isLoadingRecommendation = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching places: $e';
        _isLoadingPlaces = false;
        _isLoadingRecommendation = false;
      });
      debugPrint('Error fetching places: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Counter'),
        centerTitle: true,
        actions: [
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
      body: _errorMessage.isNotEmpty
          ? ErrorView(errorMessage: _errorMessage, onRetry: _initialize)
          : _buildDataView(),
    );
  }

  Widget _buildDataView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          StepMethodIndicator(stepService: _stepService),
          const SizedBox(height: 16),
          StepCounterCard(stepCount: _stepCount),
          const SizedBox(height: 24),
          if (_currentPosition != null)
            LocationInfoCard(
              position: _currentPosition!,
              onRefresh: _loadLocation,
            ),
          const SizedBox(height: 24),
          if (!_hasSearchedPlaces && !_isLoadingPlaces)
            ElevatedButton.icon(
              onPressed: _fetchNearbyPlaces,
              icon: const Icon(Icons.search),
              label: const Text('Search Nearby Attractions'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            )
          else ...[
            if (_currentPosition != null && _nearbyPlaces.isNotEmpty) ...[
              PlacesMap(userPosition: _currentPosition!, places: _nearbyPlaces),
              const SizedBox(height: 24),
            ],
            NearbyPlacesCard(
              places: _nearbyPlaces,
              isLoading: _isLoadingPlaces,
            ),
            const SizedBox(height: 24),
            AIRecommendationCard(
              recommendation: _recommendation,
              isLoading: _isLoadingRecommendation,
              streamingText: _streamingRecommendation,
              onRefresh: _fetchNearbyPlaces,
            ),
          ],
        ],
      ),
    );
  }
}
