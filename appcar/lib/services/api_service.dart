// lib/services/api_service.dart
import 'dart:async';
import 'dart:html' as html; // สำหรับ Flutter Web localStorage
import 'package:dio/dio.dart';
import '../config/env.dart';
import '../models/booking.dart';

class ApiService {
  final Dio _dio;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: Env.apiBaseUrl, // เช่น https://abcd.ngrok.io
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          // สำคัญ: backend คุณมี prefix /api ทุก route
          // เราจะใส่ใน path ตอนเรียก (เช่น '/api/login')
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = html.window.localStorage['token'];
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
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
      html.window.localStorage['token'] = token;
    }
    final user = data['user'] as Map<String, dynamic>?;
    if (user != null && user['phone'] != null) {
      html.window.localStorage['phone'] = '${user['phone']}';
    }
    return data;
  }

  /// สมัคร customer ปกติ (backend คืนแค่ userId)
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

  /// สมัคร vendor
  Future<int> registerVendor({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String shopName,
    required String contact,
    required String address,
  }) async {
    final resp = await _dio.post('/api/register/vendor', data: {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'shopName': shopName,
      'contact': contact,
      'address': address,
    });
    final m = resp.data as Map<String, dynamic>;
    return (m['userId'] as num).toInt();
  }

  /// สมัคร driver
  Future<int> registerDriver({
    required String name,
    required String email,
    required String phone,
    required String password,
    required double baseLat,
    required double baseLng,
    int serviceRadiusKm = 10,
  }) async {
    final resp = await _dio.post('/api/register/driver', data: {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'base_lat': baseLat,
      'base_lng': baseLng,
      'service_radius_km': serviceRadiusKm,
    });
    final m = resp.data as Map<String, dynamic>;
    return (m['userId'] as num).toInt();
  }

  void logout() {
    html.window.localStorage.remove('token');
    html.window.localStorage.remove('phone');
  }

  String? get savedPhone => html.window.localStorage['phone'];

  // ------------ BOOKINGS (ของเดิม) ------------
  Future<List<Booking>> getBookingsForCustomer(String phone) async {
    // NOTE: backend จริงของคุณให้ GET /api/bookings โดยดูจาก token “user.id”
    // method เดิมของคุณรับจาก phone — แนะนำปรับจุดเรียกให้ใช้ token แล้วดึง bookings จาก /api/bookings
    final resp = await _dio.get('/api/bookings');
    // backend ส่ง { bookings: [...] }
    final m = resp.data as Map<String, dynamic>;
    final list = (m['bookings'] as List).cast<Map<String, dynamic>>();
    // ถ้า Booking.fromJson ต้องการฟิลด์เฉพาะ ให้ map ให้ตรงก่อน
    return list.map((e) => Booking.fromJson(e)).toList();
  }

  Future<Booking> createBooking(Map<String, dynamic> payload) async {
    // backend: POST /api/bookings  (protected)
    final resp = await _dio.post('/api/bookings', data: payload);
    // คุณส่งกลับเป็น { message, booking_id, driver_required }
    // ถ้าต้องการ Booking object ให้ไป fetch รายการใหม่ หรือปรับ backend ให้คืนข้อมูล booking
    // ที่นี่จะ mock ให้เป็น Booking แบบง่าย ๆ
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

  // Queue status ของเดิม (ถ้า backend มี endpoint นี้คงไว้)
  Future<Map<String, dynamic>> getQueueStatus({String? vehicleId}) async {
    final resp = await _dio.get('/queue-status',
        queryParameters: vehicleId != null ? {'vehicle_id': vehicleId} : {});
    return resp.data as Map<String, dynamic>;
  }

  Stream<Map<String, dynamic>> queueStatusStream(
      {String? vehicleId,
      Duration interval = const Duration(seconds: 5)}) async* {
    while (true) {
      try {
        final status = await getQueueStatus(vehicleId: vehicleId);
        yield status;
      } catch (_) {}
      await Future.delayed(interval);
    }
  }

  // ---------------- CARS (เตรียมใช้ใน Step 2) ----------------
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
