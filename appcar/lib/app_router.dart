import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/customer/search_form_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignupPage());

      case '/search':
        {
          // ✅ รับ arguments แบบปลอดภัย
          final args = settings.arguments;
          final String? token =
              (args is Map<String, dynamic>) ? args['token'] as String? : null;

          // ถ้า SearchFormPage ต้องการ token แบบ non-null:
          if (token == null || token.isEmpty) {
            // ไม่มี token → พากลับไป login (หรือจะแสดงหน้า search เปล่า ๆ ก็ได้)
            return MaterialPageRoute(builder: (_) => const LoginPage());
          }

          return MaterialPageRoute(
            builder: (_) => SearchFormPage(token: token),
          );
        }

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
