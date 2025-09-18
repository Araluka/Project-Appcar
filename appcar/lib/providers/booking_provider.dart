import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  final ApiService api;
  List<Booking> _bookings = [];
  bool _loading = false;

  BookingProvider(this.api);

  List<Booking> get bookings => _bookings;
  bool get loading => _loading;

  Future<void> fetchBookings(String phone) async {
    _loading = true;
    notifyListeners();
    try {
      _bookings = await api.getBookingsForCustomer(phone);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Booking> createBooking(Map<String, dynamic> payload) async {
    final b = await api.createBooking(payload);
    _bookings.add(b);
    notifyListeners();
    return b;
  }
}
