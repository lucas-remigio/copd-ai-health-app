import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../services/pedometer_service.dart';
import '../models/place.dart';
import '../widgets/step_counter_card.dart';
import '../widgets/location_info_card.dart';
import '../widgets/nearby_places_card.dart';
import '../widgets/places_map.dart';
import '../widgets/error_view.dart';

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  final _locationService = LocationService();
  final _placesService = PlacesService();
  final _pedometerService = PedometerService();

  int _stepCount = 0;
  Position? _currentPosition;
  List<Place> _nearbyPlaces = [];
  String _errorMessage = '';
  bool _isLoadingPlaces = false;
  bool _hasSearchedPlaces = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _requestPermissions();
    _startListening();
    await _loadLocation();
  }

  Future<void> _requestPermissions() async {
    final activityStatus = await Permission.activityRecognition.request();
    final locationStatus = await Permission.location.request();

    if (!activityStatus.isGranted || !locationStatus.isGranted) {
      setState(() => _errorMessage = 'Permissions denied');
    }
  }

  void _startListening() {
    _pedometerService.stepCountStream.listen(_onStepCount, onError: _onError);
  }

  Future<void> _loadLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
        _errorMessage = '';
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

    setState(() => _isLoadingPlaces = true);

    try {
      final places = await _placesService.fetchNearbyPlaces(_currentPosition!);
      setState(() {
        _nearbyPlaces = places;
        _isLoadingPlaces = false;
        _hasSearchedPlaces = true;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching places: $e';
        _isLoadingPlaces = false;
      });
      debugPrint('Error fetching places: $e');
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
            if (_currentPosition != null && _nearbyPlaces.isNotEmpty)
              PlacesMap(userPosition: _currentPosition!, places: _nearbyPlaces),
            const SizedBox(height: 24),
            NearbyPlacesCard(
              places: _nearbyPlaces,
              isLoading: _isLoadingPlaces,
            ),
          ],
        ],
      ),
    );
  }
}
