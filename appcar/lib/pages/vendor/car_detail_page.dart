import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/token_store.dart';

class CarDetailPage extends StatelessWidget {
  final dynamic car;
  final bool isVendorView; // 👈 เพิ่ม flag

  const CarDetailPage({
    super.key,
    required this.car,
    this.isVendorView = false, // ค่า default = ลูกค้า
  });

  Future<void> _bookCar(BuildContext context) async {
    final token = await TokenStore.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาล็อกอินก่อนจองรถ")),
      );
      return;
    }

    try {
      await ApiService().createBooking(
        carId: car['id'],
        startTime: DateTime.now().toIso8601String(),
        endTime: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        driverRequired: false,
        token: token,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("จองรถสำเร็จ")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("จองรถไม่สำเร็จ: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(car['name'] ?? "รายละเอียดรถ")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            car['image_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      car['image_url'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.directions_car, size: 80),
                  ),
            const SizedBox(height: 16),
            Text(
              car['name'] ?? "ไม่มีชื่อรถ",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("ทะเบียน: ${car['license_plate'] ?? '-'}"),
            Text("ราคา: ${car['price_per_day'] ?? '-'} บาท/วัน"),
            if (car['seats'] != null) Text("จำนวนที่นั่ง: ${car['seats']}"),
            if (car['transmission'] != null)
              Text("เกียร์: ${car['transmission']}"),
            const SizedBox(height: 24),
            // 👇 แสดงปุ่มจองเฉพาะลูกค้า
            if (!isVendorView)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _bookCar(context),
                  icon: const Icon(Icons.check),
                  label: const Text("จองรถคันนี้"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
