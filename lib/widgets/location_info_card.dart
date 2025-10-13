import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationInfoCard extends StatelessWidget {
  final Position position;
  final VoidCallback onRefresh;

  const LocationInfoCard({
    super.key,
    required this.position,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Current Location',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text('Lat: ${position.latitude.toStringAsFixed(6)}'),
            Text('Long: ${position.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
