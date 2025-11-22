import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health_test_app/services/ai_llama_service.dart';
import 'package:health_test_app/services/app_state_manager.dart';
import '../models/place.dart';
import '../theme/app_theme.dart';
import '../widgets/places_map.dart';
import '../utils/map_utils.dart';

class PlacesScreen extends StatefulWidget {
  final AILlamaService aiService;

  const PlacesScreen({super.key, required this.aiService});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final _appState = AppStateManager();

  Position? _currentPosition;
  List<Place> _nearbyPlaces = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  void _loadCachedData() {
    // Load from singleton
    setState(() {
      _currentPosition = _appState.currentPosition;
      _nearbyPlaces = _appState.nearbyPlaces;
      _hasSearched = _nearbyPlaces.isNotEmpty;
    });
  }

  Future<void> _refreshLocation() async {
    try {
      await _appState.refreshLocation();
      setState(() {
        _currentPosition = _appState.currentPosition;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to get location: $e');
      debugPrint('Location error: $e');
    }
  }

  Future<void> _fetchNearbyPlaces() async {
    if (!_appState.hasLocation) {
      setState(() => _errorMessage = 'Location not available');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _appState.fetchNearbyPlaces();
      setState(() {
        _nearbyPlaces = _appState.nearbyPlaces;
        _currentPosition = _appState.currentPosition;
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
        title: const Text('Locais Próximos'),
        actions: [
          if (_hasSearched)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchNearbyPlaces,
              tooltip: 'Atualizar',
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
                _refreshLocation();
              },
              child: const Text('Tentar novamente'),
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
              'Descobrir por Perto',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Encontre lugares interessantes para caminhar por perto',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _currentPosition == null ? null : _fetchNearbyPlaces,
              icon: const Icon(Icons.search),
              label: const Text('Procurar Locais Próximos'),
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
                'Obtendo sua localização...',
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
              'Nenhum local encontrado por perto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tente procurar numa área diferente',
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
        onTap: () async {
          if (place.latitude == null || place.longitude == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Localização não disponível')),
            );
            return;
          }

          try {
            await MapUtils.openGoogleMapsDirections(
              destinationLat: place.latitude!,
              destinationLng: place.longitude!,
              placeName: place.name,
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao abrir Google Maps: $e')),
              );
            }
          }
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_walk,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.distanceInSteps,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (place.duration != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  place.durationInMinutes,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
