import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/car.dart';
import '../../services/api_service.dart';
import 'payment_success_page.dart';

class PaymentPage extends StatefulWidget {
  final String token; // ✅ รับ token จาก BookingPage
  final int bookingId;
  final Car car;
  final DateTime startDate;
  final DateTime endDate;
  final double totalCost;

  const PaymentPage({
    super.key,
    required this.token,
    required this.bookingId,
    required this.car,
    required this.startDate,
    required this.endDate,
    required this.totalCost,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedMethod = "promptpay";
  bool _loading = false;
  String? _error;

  Future<void> _confirmPayment() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService().createPayment(
        bookingId: widget.bookingId,
        amount: widget.totalCost,
        method: _selectedMethod,
        token: widget.token, // ✅ ใช้ token ที่ส่งมาจาก BookingPage
      );

      // ✅ Debug log
      print("Payment response: $response");

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
            token: widget.token, // ✅ ส่ง token ต่อไป
            bookingId: widget.bookingId,
            car: widget.car,
            startDate: widget.startDate,
            endDate: widget.endDate,
            totalCost: widget.totalCost,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = "Payment failed: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.car.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.car.imageUrl,
                              width: 120,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.directions_car, size: 80),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.car.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                              "${formatter.format(widget.startDate)} → ${formatter.format(widget.endDate)}"),
                          Text("รวม: ฿${widget.totalCost.toStringAsFixed(0)}",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Text("เลือกวิธีชำระเงิน",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            RadioListTile<String>(
              value: "promptpay",
              groupValue: _selectedMethod,
              onChanged: (val) => setState(() => _selectedMethod = val!),
              title: const Text("PromptPay QR (จำลอง)"),
              secondary: const Icon(Icons.qr_code),
            ),
            RadioListTile<String>(
              value: "credit_card",
              groupValue: _selectedMethod,
              onChanged: (val) => setState(() => _selectedMethod = val!),
              title: const Text("Credit / Debit Card (จำลอง)"),
              secondary: const Icon(Icons.credit_card),
            ),
            RadioListTile<String>(
              value: "mobile_banking",
              groupValue: _selectedMethod,
              onChanged: (val) => setState(() => _selectedMethod = val!),
              title: const Text("Mobile Banking (จำลอง)"),
              secondary: const Icon(Icons.account_balance),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _confirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ยืนยันและชำระเงิน",
                      style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
