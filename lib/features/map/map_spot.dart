class MapSpot {
  final String id;
  final String name;
  final String country;

  // Store real coordinates
  final double lat;
  final double lng;

  final String notes;

  const MapSpot({
    required this.id,
    required this.name,
    required this.country,
    required this.lat,
    required this.lng,
    required this.notes,
  });
}
