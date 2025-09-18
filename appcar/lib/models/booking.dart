class Booking {
  final String id;
  final String customerName;
  final String phone;
  final String vehicleId;
  final String status;
  final String queueNo;

  Booking({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.vehicleId,
    required this.status,
    required this.queueNo,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['booking_id']?.toString() ?? json['id']?.toString() ?? '',
      customerName: json['customer_name'] ?? json['name'] ?? '',
      phone: json['phone'] ?? '',
      vehicleId: json['vehicle_id']?.toString() ?? '',
      status: json['status'] ?? '',
      queueNo: json['queue_no']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'booking_id': id,
        'customer_name': customerName,
        'phone': phone,
        'vehicle_id': vehicleId,
        'status': status,
        'queue_no': queueNo,
      };
}
