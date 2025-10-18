class Place {
  final String name;
  final double? latitude;
  final double? longitude;
  final int? distance;
  final int? duration;

  Place({
    required this.name,
    this.latitude,
    this.longitude,
    this.distance,
    this.duration,
  });

  factory Place.fromJson(
    Map<String, dynamic> json, {
    int? distanceMeters,
    int? durationSeconds,
  }) {
    return Place(
      name: json['displayName']?['text'] ?? 'Unknown',
      latitude: json['location']?['latitude'] as double?,
      longitude: json['location']?['longitude'] as double?,
      distance: distanceMeters,
      duration: durationSeconds,
    );
  }

  String get distanceInKm => distance != null
      ? '${(distance! / 1000).toStringAsFixed(2)} km away'
      : 'Distance unknown';

  String get durationInMinutes {
    if (duration == null) return '';
    final minutes = (duration! / 60).round();
    return '~$minutes min walk';
  }

  String get distanceInSteps {
    if (distance == null) return 'Distance unknown';
    final steps = (distance! / 0.762).round(); // Average step length ~0.762m
    return '$steps steps away';
  }
}
