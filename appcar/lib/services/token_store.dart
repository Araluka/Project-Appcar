import 'token_store_io.dart' if (dart.library.html) 'token_store_web.dart';

abstract class TokenStore {
  static Future<void> saveToken(String token) async {
    await TokenStoreImpl.saveToken(token);
  }

  static Future<String?> getToken() async {
    return await TokenStoreImpl.getToken();
  }

  static Future<void> clearToken() async {
    await TokenStoreImpl.clearToken();
  }
}
