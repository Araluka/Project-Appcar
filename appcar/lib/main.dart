import 'package:flutter/material.dart';
import 'app_router.dart';
import 'config/env.dart';

void main() {
  // อ่านจาก --dart-define
  const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  Env.init(apiBaseUrl: apiBaseUrl);

  runApp(const AppCar());
}

class AppCar extends StatelessWidget {
  const AppCar({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppCar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/login',
    );
  }
}
