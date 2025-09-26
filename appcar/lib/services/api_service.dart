import 'package:dio/dio.dart';
import '../config/env.dart';
import '../models/car.dart';
import '../models/booking.dart'; // ✅ เพิ่มบรรทัดนี้

class ApiService {
  final Dio _dio;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  // ---------------- AUTH ----------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/api/login', data: {
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String phone, {
    String role = "customer", // ✅ default = customer
  }) async {
    final response = await _dio.post('/api/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
    });
    return Map<String, dynamic>.from(response.data);
  }

  // ---------------- CARS ----------------
  Future<List<Car>> searchCars({
    required double locationLat,
    required double locationLng,
    required String startTime,
    required String endTime,
    String? token,
  }) async {
    final response = await _dio.get(
      '/api/cars/search',
      queryParameters: {
        'location_lat': locationLat,
        'location_lng': locationLng,
        'start_time': startTime,
        'end_time': endTime,
      },
      options: token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null,
    );

    final data = response.data as List;
    return data.map((c) => Car.fromJson(c)).toList();
  }

  // ---------------- BOOKINGS ----------------
  Future<Map<String, dynamic>> createBooking({
    required int carId,
    required String startTime,
    required String endTime,
    required bool driverRequired,
    required String token,
  }) async {
    final response = await _dio.post(
      '/api/bookings',
      data: {
        'car_id': carId,
        'start_time': startTime,
        'end_time': endTime,
        'driver_required': driverRequired ? 1 : 0,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<Booking>> getCustomerBookings(String token) async {
    final response = await _dio.get(
      '/api/bookings/my',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = response.data as List;
    return data.map((b) => Booking.fromJson(b)).toList();
  }

  // ✅ Booking detail
  Future<Map<String, dynamic>> getBookingDetail(
      int bookingId, String token) async {
    final response = await _dio.get(
      '/api/bookings/$bookingId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Map<String, dynamic>.from(response.data);
  }

  // ---------------- PROFILE ----------------
  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await _dio.get(
      '/api/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Map<String, dynamic>.from(response.data);
  }

  // ---------------- NOTIFICATIONS ----------------
  Future<List<dynamic>> getMyNotifications(String token) async {
    final response = await _dio.get(
      '/api/notifications/my',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  // ---------------- RECEIPTS ----------------
  Future<List<dynamic>> getMyReceipts(String token) async {
    final response = await _dio.get(
      '/api/receipts/my',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  // ---------------- PAYMENTS ----------------
  Future<Map<String, dynamic>> createPayment({
    required int bookingId,
    required double amount,
    required String method,
    required String token,
  }) async {
    final response = await _dio.post(
      '/api/payments',
      data: {
        'booking_id': bookingId,
        'transaction_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'payment_method': method,
        'amount': amount,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Map<String, dynamic>.from(response.data);
  }

  // ---------------- CANCEL BOOKING ----------------
  Future<Map<String, dynamic>> cancelBooking(
      int bookingId, String token) async {
    final response = await _dio.patch(
      '/api/bookings/$bookingId/cancel',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Map<String, dynamic>.from(response.data);
  }

  // ---------------- VENDOR BOOKINGS ----------------
  Future<List<Booking>> getVendorBookings(String token) async {
    final response = await _dio.get(
      '/api/vendor/my-bookings',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = response.data as List;
    return data.map((b) => Booking.fromJson(b)).toList();
  }

  // ✅ Vendor return car
  Future<Map<String, dynamic>> returnBooking(
      int bookingId, String token) async {
    final response = await _dio.patch(
      '/api/bookings/$bookingId/return',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Map<String, dynamic>.from(response.data);
  }

  // ---------------- VENDOR CARS ----------------
  Future<List<Map<String, dynamic>>> getMyCars(String token) async {
    final response = await _dio.get(
      '/api/cars/my',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> addCar(
      Map<String, dynamic> carData, String token) async {
    final response = await _dio.post(
      '/api/cars',
      data: carData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> updateCar(
      int carId, Map<String, dynamic> carData, String token) async {
    final response = await _dio.put(
      '/api/cars/$carId',
      data: carData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> deleteCar(int carId, String token) async {
    final response = await _dio.delete(
      '/api/cars/$carId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Map<String, dynamic>.from(response.data);
  }

  // ---------------- VENDOR BOOKING DETAIL ----------------
  Future<Map<String, dynamic>> getVendorBookingDetail(
      int bookingId, String token) async {
    final response = await _dio.get(
      '/api/vendor/booking/$bookingId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Map<String, dynamic>.from(response.data);
  }
}
