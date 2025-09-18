// lib/services/api_service.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio/browser.dart'; // ✅ สำหรับ Flutter Web
import '../models/booking.dart';
import 'token_store.dart';

class ApiService {
  final Dio _dio;

  ApiService({required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    // ✅ ให้ทำงานกับ Flutter Web
    _dio.httpClientAdapter = BrowserHttpClientAdapter();

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStore.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  // ---------------- AUTH ----------------
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final resp = await _dio.post('/api/login', data: {
      'email': email,
      'password': password,
    });

    final data = resp.data as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token != null) {
      await TokenStore.save(token);
    }
    final user = data['user'] as Map<String, dynamic>?;
    if (user?['phone'] != null) {
      await TokenStore.savePhone('${user!['phone']}');
    }
    return data;
  }

  Future<int> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final resp = await _dio.post('/api/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    });
    final m = resp.data as Map<String, dynamic>;
    return (m['userId'] as num).toInt();
  }

  Future<void> logout() async {
    await TokenStore.clear();
  }

  Future<String?> get savedPhone async => TokenStore.readPhone();

  // ---------------- BOOKINGS ----------------
  Future<List<Booking>> getBookingsForCustomer(String phoneIgnored) async {
    final resp = await _dio.get('/api/bookings');
    final m = resp.data as Map<String, dynamic>;
    final list = (m['bookings'] as List).cast<Map<String, dynamic>>();
    return list.map((e) => Booking.fromJson(e)).toList();
  }

  Future<Booking> createBooking(Map<String, dynamic> payload) async {
    final resp = await _dio.post('/api/bookings', data: payload);
    final data = resp.data as Map<String, dynamic>;
    return Booking.fromJson({
      'id': data['booking_id'],
      'status': 'pending',
      ...payload,
    });
  }

  Future<void> cancelBooking(int bookingId) async {
    await _dio.patch('/api/bookings/$bookingId/cancel');
  }

  // ---------------- CARS ----------------
  Future<List<Map<String, dynamic>>> searchCars({
    required DateTime date,
    required double startLat,
    required double startLng,
    double radiusKm = 10,
  }) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final start =
        '${startLat.toStringAsFixed(6)},${startLng.toStringAsFixed(6)}';
    final resp = await _dio.get('/api/cars/search', queryParameters: {
      'date': dateStr,
      'start': start,
      'radius': radiusKm,
    });
    final m = resp.data as Map<String, dynamic>;
    return (m['cars'] as List).cast<Map<String, dynamic>>();
  }
}
