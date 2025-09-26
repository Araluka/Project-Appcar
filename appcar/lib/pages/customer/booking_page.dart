import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/car.dart';
import '../../services/api_service.dart';
import '../../config/env.dart';
import 'payment_page.dart';

class BookingPage extends StatefulWidget {
  final String token; // ✅ เพิ่ม token
  final Car car;
  final DateTime startDate;
  final DateTime endDate;

  const BookingPage({
    super.key,
    required this.token,
    required this.car,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool _driverRequired = false;
  bool _loading = false;
  String? _error;

  final int driverFeePerDay = 100; // mock driver fee ต่อวัน

  Future<void> _confirmBooking() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService().createBooking(
        carId: widget.car.id,
        startTime: widget.startDate.toIso8601String(),
        endTime: widget.endDate.toIso8601String(),
        driverRequired: _driverRequired,
        token: widget.token, // ✅ ใช้ token ที่ส่งมาจากหน้า CarDetailPage
      );

      // ✅ Debug log
      print("Booking response: $response");

      final bookingId = response['booking_id'] ?? response['bookingId'];

      if (bookingId != null) {
        final days = widget.endDate.difference(widget.startDate).inDays;
        final carCost = days * widget.car.pricePerDay;
        final driverCost = _driverRequired ? days * driverFeePerDay : 0;
        final totalCost = carCost + driverCost;

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentPage(
              token: widget.token, // ✅ ส่ง token ไป PaymentPage
              bookingId: bookingId,
              car: widget.car,
              startDate: widget.startDate,
              endDate: widget.endDate,
              totalCost: totalCost.toDouble(),
            ),
          ),
        );
      } else {
        setState(() {
          _error = "Booking failed: booking_id not found in response";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Booking failed: $e";
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
    final days = widget.endDate.difference(widget.startDate).inDays;
    final carCost = days * widget.car.pricePerDay;
    final driverCost = _driverRequired ? days * driverFeePerDay : 0;
    final totalCost = carCost + driverCost;

    return Scaffold(
      appBar: AppBar(title: const Text("Order")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Car summary
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.car.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              "${Env.apiBaseUrl}${widget.car.imageUrl}",
                              width: 120,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.directions_car, size: 80),
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
                          Text("${widget.car.seats} ที่นั่ง"),
                          Text(widget.car.transmission),
                        ],
                      ),
                    ),
                    Text("${widget.car.pricePerDay.toStringAsFixed(0)}/วัน",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Booking date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("วันที่จอง",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("$days วัน"),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${formatter.format(widget.startDate)} - ${formatter.format(widget.endDate)}",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),

            // ✅ Driver option
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ต้องการคนขับ (+฿100/วัน)",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Switch(
                  value: _driverRequired,
                  onChanged: (val) {
                    setState(() {
                      _driverRequired = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ✅ Price summary
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black26),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("ค่ารถ"),
                        Text("฿${carCost.toStringAsFixed(0)}"),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("ค่าคนขับ"),
                        Text("฿${driverCost.toStringAsFixed(0)}"),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("รวม",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("฿${totalCost.toStringAsFixed(0)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("เช่าเลย", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
