// lib/services/token_store_web.dart
import 'dart:html' as html;

class TokenStore {
  static const _kToken = 'token';
  static const _kPhone = 'phone';

  static Future<void> save(String token) async {
    html.window.localStorage[_kToken] = token;
  }

  static Future<String?> read() async {
    return html.window.localStorage[_kToken];
  }

  static Future<void> clear() async {
    html.window.localStorage.remove(_kToken);
    html.window.localStorage.remove(_kPhone);
  }

  static Future<void> savePhone(String phone) async {
    html.window.localStorage[_kPhone] = phone;
  }

  static Future<String?> readPhone() async {
    return html.window.localStorage[_kPhone];
  }
}
