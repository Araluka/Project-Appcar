import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/car.dart';
import 'home_page.dart';
import 'home_status_page.dart';

class PaymentSuccessPage extends StatelessWidget {
  final int bookingId;
  final Car car;
  final DateTime startDate;
  final DateTime endDate;
  final double totalCost;

  const PaymentSuccessPage({
    super.key,
    required this.bookingId,
    required this.car,
    required this.startDate,
    required this.endDate,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy');
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 16),
              const Text("การชำระเงินสำเร็จ!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text("Booking #$bookingId",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(car.name),
                      Text(
                          "${formatter.format(startDate)} → ${formatter.format(endDate)}"),
                      const SizedBox(height: 8),
                      Text("ยอดที่จ่าย: ฿${totalCost.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerHomePage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text("กลับหน้า Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
