// lib/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl =
      'http://your_backend_url/api'; // แทนที่ 'your_backend_url' ด้วย URL ของ Backend

  // สมัครสมาชิก
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      return json.decode(response.body); // สมัครสำเร็จ
    } else {
      throw Exception('เกิดข้อผิดพลาดในการสมัคร');
    }
  }

  // เข้าสู่ระบบ
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: json.encode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body); // เข้าสู่ระบบสำเร็จ
    } else {
      throw Exception('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    }
  }
}
