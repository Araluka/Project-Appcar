import 'package:flutter/material.dart';
import '../models/booking.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  const BookingCard({required this.booking, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text(booking.customerName),
        subtitle:
            Text('Vehicle: ${booking.vehicleId} • Queue: ${booking.queueNo}'),
        trailing: Text(booking.status),
      ),
    );
  }
}
