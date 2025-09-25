import 'dart:html' as html;

class TokenStoreImpl {
  static Future<void> saveToken(String token) async {
    html.window.localStorage['token'] = token;
  }

  static Future<String?> getToken() async {
    return html.window.localStorage['token'];
  }

  static Future<void> clearToken() async {
    html.window.localStorage.remove('token');
  }
}
