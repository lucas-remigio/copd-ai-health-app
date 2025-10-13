class Place {
  final String name;
  final double? latitude;
  final double? longitude;
  final int? distance;

  Place({required this.name, this.latitude, this.longitude, this.distance});

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      name: json['displayName']?['text'] ?? 'Unknown',
      latitude: json['location']?['latitude'],
      longitude: json['location']?['longitude'],
      distance: json['routingSummaries']?[0]?['legs']?[0]?['distanceMeters'],
    );
  }

  String get distanceInKm => distance != null
      ? '${(distance! / 1000).toStringAsFixed(2)} km away'
      : 'Distance unknown';
}
