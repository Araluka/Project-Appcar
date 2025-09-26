class Booking {
  final int id;
  final int carId;
  final String carName;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String? customerName;
  final double pricePerDay;
  final bool driverRequired;

  Booking({
    required this.id,
    required this.carId,
    required this.carName,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.customerName,
    required this.pricePerDay,
    required this.driverRequired,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['booking_id'] is int
          ? json['booking_id'] as int
          : json['id'] is int
              ? json['id'] as int
              : int.tryParse(json['booking_id']?.toString() ??
                      json['id']?.toString() ??
                      '') ??
                  0,
      carId: json['car_id'] is int
          ? json['car_id'] as int
          : int.tryParse(json['car_id']?.toString() ?? '') ?? 0,
      carName: json['car_name']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'pending',
      startDate: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      customerName: json['customer_name']?.toString(),
      pricePerDay: json['price_per_day'] is num
          ? (json['price_per_day'] as num).toDouble()
          : double.tryParse(json['price_per_day']?.toString() ?? '') ?? 0.0,
      driverRequired: (json['driver_required'] ?? 0) == 1,
    );
  }
}
