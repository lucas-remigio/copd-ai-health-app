import 'package:flutter/material.dart';
import '../models/place.dart';
import '../utils/map_utils.dart';

class NearbyPlacesCard extends StatelessWidget {
  final List<Place> places;
  final bool isLoading;

  const NearbyPlacesCard({
    super.key,
    required this.places,
    required this.isLoading,
  });

  Future<void> _openInGoogleMaps(BuildContext context, Place place) async {
    if (place.latitude == null || place.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available for this place')),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open Google Maps: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nearby Attractions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (places.isEmpty)
              const Text('No places found nearby')
            else
              ...places.map(
                (place) => ListTile(
                  leading: const Icon(Icons.place, color: Colors.blue),
                  title: Text(place.name),
                  subtitle: Text(
                    '${place.distanceInKm} • ${place.distanceInSteps}${place.durationInMinutes.isNotEmpty ? ' • ${place.durationInMinutes}' : ''}',
                  ),
                  trailing: const Icon(Icons.directions, color: Colors.blue),
                  onTap: () => _openInGoogleMaps(context, place),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
