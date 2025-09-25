class Booking {
  final int id;
  final String carName;
  final String vendorName;
  final String startTime;
  final String endTime;
  final String status;

  Booking({
    required this.id,
    required this.carName,
    required this.vendorName,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: int.tryParse(json['id'].toString()) ?? 0,
      carName: json['car_name'] ?? '',
      vendorName: json['vendor_name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
