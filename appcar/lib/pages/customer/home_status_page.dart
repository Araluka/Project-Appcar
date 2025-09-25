import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import '../../services/token_store.dart';

class HomeStatusPage extends StatefulWidget {
  const HomeStatusPage({super.key});

  @override
  State<HomeStatusPage> createState() => _HomeStatusPageState();
}

class _HomeStatusPageState extends State<HomeStatusPage> {
  Future<Booking?>? _activeBooking;

  @override
  void initState() {
    super.initState();
    _activeBooking = _fetchActiveBooking();
  }

  Future<Booking?> _fetchActiveBooking() async {
    final token = await TokenStore.getToken();
    final bookings = await ApiService().getMyBookings(token!);
    // สมมุติว่า booking ตัวล่าสุดคือ "active"
    if (bookings.isNotEmpty) {
      return bookings.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Booking")),
      body: FutureBuilder<Booking?>(
        future: _activeBooking,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No active booking"));
          }

          final booking = snapshot.data!;
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Car: ${booking.carName}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Vendor: ${booking.vendorName}"),
                  Text("Start: ${booking.startTime}"),
                  Text("End: ${booking.endTime}"),
                  const SizedBox(height: 12),
                  Text("Status: ${booking.status}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
