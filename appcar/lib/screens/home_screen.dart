import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  StreamSubscription? _queueSub;
  Map<String, dynamic>? _queueStatus;

  @override
  void initState() {
    super.initState();
    _queueSub = _api
        .queueStatusStream(interval: const Duration(seconds: 5))
        .listen((status) {
      setState(() {
        _queueStatus = status;
      });
    });
  }

  @override
  void dispose() {
    _queueSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AppCar-Araluka')),
      body: Column(
        children: [
          if (_queueStatus != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Queue status: ${_queueStatus.toString()}'),
            ),
          ElevatedButton(
            onPressed: () => provider.fetchBookings('0800000000'),
            child: const Text('Load my bookings (example)'),
          ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: provider.bookings.length,
                    itemBuilder: (ctx, i) {
                      final b = provider.bookings[i];
                      return ListTile(
                        title: Text('${b.customerName} - ${b.vehicleId}'),
                        subtitle:
                            Text('Queue: ${b.queueNo} - Status: ${b.status}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
