import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';

class PlacesService {
  static final String _apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  Future<List<Place>> fetchNearbyPlaces(Position position) async {
    final response = await http.post(
      Uri.parse('https://places.googleapis.com/v1/places:searchNearby'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'places.displayName,places.location,routingSummaries',
      },
      body: jsonEncode({
        'includedPrimaryTypes': [
          'cultural_landmark',
          'park',
          'tourist_attraction',
        ],
        'maxResultCount': 10,
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
            'radius': 5000,
          },
        },
        'routingParameters': {
          'origin': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'travelMode': 'WALK',
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['places'] as List?)
              ?.map((place) => Place.fromJson(place))
              .toList() ??
          [];
    } else {
      throw Exception('Failed to load places: ${response.statusCode}');
    }
  }
}
