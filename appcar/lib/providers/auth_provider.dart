// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api;
  bool _loading = false;
  Map<String, dynamic>? _user;

  AuthProvider(this.api);

  bool get isLoading => _loading;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await api.login(email: email, password: password);
      _user = res['user'] as Map<String, dynamic>?;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// สมัครแล้ว “ให้ผู้ใช้กลับไป Login” (เพราะ backend ไม่ได้คืน token)
  Future<int> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final id = await api.registerCustomer(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      return id;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void logout() {
    api.logout();
    _user = null;
    notifyListeners();
  }
}
