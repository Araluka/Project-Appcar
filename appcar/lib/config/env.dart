import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';
  static String get wsUrl => dotenv.env['WS_URL'] ?? 'ws://10.0.2.2:8000/ws';
}
