class Place {
  final String name;
  final double? latitude;
  final double? longitude;
  final int? distance;

  Place({required this.name, this.latitude, this.longitude, this.distance});

  factory Place.fromJson(Map<String, dynamic> json) {
    print('Parsing place JSON: $json');
    final distanceValue =
        json['routingSummaries']?[0]?['legs']?[0]?['distanceMeters'];
    print(
      'Distance value: $distanceValue (type: ${distanceValue.runtimeType})',
    );

    return Place(
      name: json['displayName']?['text'] ?? 'Unknown',
      latitude: json['location']?['latitude'],
      longitude: json['location']?['longitude'],
      distance: distanceValue,
    );
  }

  String get distanceInKm => distance != null
      ? '${(distance! / 1000).toStringAsFixed(2)} km away'
      : 'Distance unknown';
}
