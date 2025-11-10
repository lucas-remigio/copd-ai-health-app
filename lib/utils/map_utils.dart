import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class MapUtils {
  /// Opens Google Maps with the specified location
  static Future<void> openGoogleMaps({
    required double latitude,
    required double longitude,
    String? placeName,
  }) async {
    // Build the Google Maps URL
    final query = placeName != null
        ? Uri.encodeComponent(placeName)
        : '$latitude,$longitude';

    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    // Alternative: Direct navigation URL
    // final googleMapsUrl = Uri.parse(
    //   'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    // );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open Google Maps');
      }
    } catch (e) {
      debugPrint('Error opening Google Maps: $e');
      rethrow;
    }
  }

  /// Opens Google Maps with directions from current location to destination
  static Future<void> openGoogleMapsDirections({
    required double destinationLat,
    required double destinationLng,
    String? placeName,
  }) async {
    final destination = '$destinationLat,$destinationLng';
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=walking',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open Google Maps');
      }
    } catch (e) {
      debugPrint('Error opening Google Maps: $e');
      rethrow;
    }
  }
}
