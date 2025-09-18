import 'dart:async';
import 'package:dio/dio.dart';
import '../config/env.dart';
import '../models/booking.dart';

class ApiService {
  final Dio _dio;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  Future<List<Booking>> getBookingsForCustomer(String phone) async {
    final resp = await _dio.get('/bookings', queryParameters: {'phone': phone});
    final data = resp.data as List<dynamic>;
    return data
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Booking> createBooking(Map<String, dynamic> payload) async {
    final resp = await _dio.post('/bookings/create', data: payload);
    return Booking.fromJson(resp.data as Map<String, dynamic>);
  }

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
      } catch (e) {
        // ignore or optionally yield error info
      }
      await Future.delayed(interval);
    }
  }
}
