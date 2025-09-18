// lib/services/token_store_io.dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _kToken = 'token';
  static const _kPhone = 'phone';

  static Future<void> save(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kToken, token);
  }

  static Future<String?> read() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kToken);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kToken);
    await sp.remove(_kPhone);
  }

  static Future<void> savePhone(String phone) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kPhone, phone);
  }

  static Future<String?> readPhone() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kPhone);
  }
}
