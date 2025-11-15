import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health_test_app/services/ai_llama_service.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../models/place.dart';
import '../theme/app_theme.dart';
import '../widgets/places_map.dart';

class PlacesScreen extends StatefulWidget {
  final AILlamaService aiService;

  const PlacesScreen({super.key, required this.aiService});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final _locationService = LocationService();
  final _placesService = PlacesService();

  Position? _currentPosition;
  List<Place> _nearbyPlaces = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() => _currentPosition = position);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to get location: $e');
      debugPrint('Location error: $e');
    }
  }

  Future<void> _fetchNearbyPlaces() async {
    if (_currentPosition == null) {
      setState(() => _errorMessage = 'Location not available');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final places = await _placesService.fetchNearbyPlaces(_currentPosition!);
      setState(() {
        _nearbyPlaces = places;
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch places: $e';
        _isLoading = false;
      });
      debugPrint('Error fetching places: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Places'),
        actions: [
          if (_hasSearched)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchNearbyPlaces,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (!_hasSearched) {
      return _buildSearchPrompt();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_nearbyPlaces.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPlacesList();
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() => _errorMessage = null);
                _loadLocation();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore,
                size: 80,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Discover Nearby',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Find interesting places to walk to',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _currentPosition == null ? null : _fetchNearbyPlaces,
              icon: const Icon(Icons.search),
              label: const Text('Search Nearby Places'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            if (_currentPosition == null) ...[
              const SizedBox(height: 16),
              const Text(
                'Getting your location...',
                style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No places found nearby',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching in a different area',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacesList() {
    return CustomScrollView(
      slivers: [
        // Map section
        if (_currentPosition != null)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 250,
              child: PlacesMap(
                userPosition: _currentPosition!,
                places: _nearbyPlaces,
              ),
            ),
          ),

        // Places list
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final place = _nearbyPlaces[index];
              return _buildPlaceCard(place, index);
            }, childCount: _nearbyPlaces.length),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceCard(Place place, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Could add navigation or details here
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Number badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Place info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_walk,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          place.distanceInSteps,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (place.duration != null) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            place.durationInMinutes,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow icon
              const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
