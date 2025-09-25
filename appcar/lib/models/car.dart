class Car {
  final int id;
  final String name;
  final String licensePlate;
  final String imageUrl;
  final int seats;
  final String transmission;
  final int bagSmall;
  final int bagLarge;
  final int unlimitedMileage;
  final double pricePerDay;
  final int freeCancellation;
  final double? locationLat;
  final double? locationLng;
  final int isAvailable;
  final String vendorName;

  Car({
    required this.id,
    required this.name,
    required this.licensePlate,
    required this.imageUrl,
    required this.seats,
    required this.transmission,
    required this.bagSmall,
    required this.bagLarge,
    required this.unlimitedMileage,
    required this.pricePerDay,
    required this.freeCancellation,
    required this.locationLat,
    required this.locationLng,
    required this.isAvailable,
    required this.vendorName,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      imageUrl: json['image_url'] ?? '',
      seats: int.tryParse(json['seats']?.toString() ?? '') ?? 0,
      transmission: json['transmission'] ?? '',
      bagSmall: int.tryParse(json['bag_small']?.toString() ?? '') ?? 0,
      bagLarge: int.tryParse(json['bag_large']?.toString() ?? '') ?? 0,
      unlimitedMileage:
          int.tryParse(json['unlimited_mileage']?.toString() ?? '') ?? 1,
      pricePerDay:
          double.tryParse(json['price_per_day']?.toString() ?? '') ?? 0.0,
      freeCancellation:
          int.tryParse(json['free_cancellation']?.toString() ?? '') ?? 1,
      locationLat: json['location_lat'] != null
          ? double.tryParse(json['location_lat'].toString())
          : null,
      locationLng: json['location_lng'] != null
          ? double.tryParse(json['location_lng'].toString())
          : null,
      isAvailable: int.tryParse(json['is_available']?.toString() ?? '') ?? 1,
      vendorName: json['vendor_name'] ?? '',
    );
  }
}
