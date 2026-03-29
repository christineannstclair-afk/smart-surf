class SurfSpot {
  final String id;
  final String name;
  final String country;
  final String region;
  final double lat;
  final double lng;
  final String difficulty;
  final String notes;
  final DateTime createdAt;

  const SurfSpot({
    required this.id,
    required this.name,
    this.country = '',
    this.region = '',
    required this.lat,
    required this.lng,
    this.difficulty = 'Beginner',
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'region': region,
        'lat': lat,
        'lng': lng,
        'difficulty': difficulty,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  static SurfSpot fromJson(Map<String, dynamic> json) {
    return SurfSpot(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
      region: (json['region'] as String?) ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      difficulty: (json['difficulty'] as String?) ?? 'Beginner',
      notes: (json['notes'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
