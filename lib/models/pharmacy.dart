class Pharmacy {
  final String id;
  final String name;
  final String address;
  double? distance; // Changed to nullable double for calculated distance
  final bool isOpen;
  final String imageUrl; // Placeholder for image
  final double? latitude;
  final double? longitude;

  // Add missing fields from Places API (nullable)
  final double? rating;
  final int? userRatingsTotal;
  final String? phoneNumber;
  final String? website;
  final List<String>? openingHours;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.isOpen,
    required this.imageUrl,
    this.latitude,
    this.longitude,
    this.distance, // Make distance optional in constructor
    this.rating,
    this.userRatingsTotal,
    this.phoneNumber,
    this.website,
    this.openingHours,
  });
}
