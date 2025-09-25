class Booking {
  final int id;
  final String carName;
  final String vendorName;
  final String? customerName; // ✅ เฉพาะ vendor จะได้ค่ามา
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool driverRequired;

  Booking({
    required this.id,
    required this.carName,
    required this.vendorName,
    this.customerName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.driverRequired,
  });

  // ✅ getter ให้เรียกชื่อแบบเก่าได้ (กันโค้ดเก่าไม่พัง)
  DateTime get startTime => startDate;
  DateTime get endTime => endDate;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      carName: json['car_name'] ?? '',
      vendorName: json['vendor_name'] ?? '',
      customerName: json['customer_name'], // จะเป็น null ถ้า backend ไม่ส่งมา
      startDate: DateTime.parse(json['start_time']),
      endDate: DateTime.parse(json['end_time']),
      status: json['status'] ?? '',
      driverRequired: (json['driver_required'] ?? 0) == 1,
    );
  }
}
