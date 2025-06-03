class Pharmacy {
  final String id;
  final String name;
  final String address;
  final double? distance;
  final bool isOpen;
  final String imageUrl;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? userRatingsTotal;
  final String? phoneNumber;
  final String? website;
  final List<String>? openingHours;
  const Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.isOpen,
    required this.imageUrl,
    this.latitude,
    this.longitude,
    this.distance,
    this.rating,
    this.userRatingsTotal,
    this.phoneNumber,
    this.website,
    this.openingHours,
  });
  Pharmacy copyWith({
    String? id,
    String? name,
    String? address,
    double? distance,
    bool? isOpen,
    String? imageUrl,
    double? latitude,
    double? longitude,
    double? rating,
    int? userRatingsTotal,
    String? phoneNumber,
    String? website,
    List<String>? openingHours,
  }) {
    return Pharmacy(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      distance: distance ?? this.distance,
      isOpen: isOpen ?? this.isOpen,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      openingHours: openingHours ?? this.openingHours,
    );
  }
}