import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../models/place.dart';

class PlacesService {
  static final String _apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
  static const String _baseUrl =
      'https://places.googleapis.com/v1/places:searchNearby';
  static const int _searchRadius = 5000;
  static const int _maxResults = 10;

  Future<List<Place>> fetchNearbyPlaces(Position position) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY') {
      throw Exception(
        'Google Places API key is missing. Set GOOGLE_PLACES_API_KEY in .env.',
      );
    }

    final response = await _makeApiRequest(position);

    if (response.statusCode != 200) {
      debugPrint('API Error: ${response.statusCode}');
      debugPrint('API Error body: ${response.body}');

      if (response.statusCode == 403) {
        throw Exception(
          'Failed to load places: 403 (API key/permissions issue). '
          'Enable Places API (New), attach billing, and verify key restrictions.',
        );
      }

      throw Exception('Failed to load places: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final places = _parsePlaces(data);

    return _sortByDistance(places);
  }

  Future<http.Response> _makeApiRequest(Position position) async {
    return await http.post(
      Uri.parse(_baseUrl),
      headers: _buildHeaders(),
      body: jsonEncode(_buildRequestBody(position)),
    );
  }

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask': 'places.displayName,places.location,routingSummaries',
    };
  }

  Map<String, dynamic> _buildRequestBody(Position position) {
    return {
      'includedPrimaryTypes': [
        'cultural_landmark',
        'park',
        'tourist_attraction',
      ],
      'maxResultCount': _maxResults,
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'radius': _searchRadius,
        },
      },
      'routingParameters': {
        'origin': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'travelMode': 'WALK',
      },
    };
  }

  List<Place> _parsePlaces(Map<String, dynamic> data) {
    final placesList = data['places'] as List?;
    final routingSummaries = data['routingSummaries'] as List?;

    if (placesList == null || placesList.isEmpty) {
      debugPrint('No places found');
      return [];
    }

    final places = <Place>[];
    for (int i = 0; i < placesList.length; i++) {
      final place = _createPlace(placesList[i], routingSummaries, i);
      places.add(place);
    }

    debugPrint('Found ${places.length} places');
    return places;
  }

  Place _createPlace(
    Map<String, dynamic> placeJson,
    List<dynamic>? routingSummaries,
    int index,
  ) {
    final routingData = _extractRoutingData(routingSummaries, index);
    return Place.fromJson(
      placeJson,
      distanceMeters: routingData['distance'],
      durationSeconds: routingData['duration'],
    );
  }

  Map<String, int?> _extractRoutingData(
    List<dynamic>? routingSummaries,
    int index,
  ) {
    final legs = routingSummaries?[index]?['legs']?[0];
    return {
      'distance': legs?['distanceMeters'] as int?,
      'duration': _parseDuration(legs?['duration']),
    };
  }

  int? _parseDuration(String? durationString) {
    if (durationString == null) return null;
    // Remove the 's' suffix and parse as int
    return int.tryParse(durationString.replaceAll('s', ''));
  }

  List<Place> _sortByDistance(List<Place> places) {
    places.sort((a, b) {
      if (a.distance == null) return 1;
      if (b.distance == null) return -1;
      return a.distance!.compareTo(b.distance!);
    });
    return places;
  }
}
