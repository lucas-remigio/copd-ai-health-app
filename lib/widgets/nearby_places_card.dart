import 'package:flutter/material.dart';
import '../models/place.dart';

class NearbyPlacesCard extends StatelessWidget {
  final List<Place> places;
  final bool isLoading;

  const NearbyPlacesCard({
    super.key,
    required this.places,
    required this.isLoading,
  });

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
                    '${place.distanceInKm}${place.durationInMinutes.isNotEmpty ? ' • ${place.durationInMinutes}' : ''}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
