// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp(apiBaseUrl: "https://abcd.ngrok.io"));
}

class MyApp extends StatelessWidget {
  final String apiBaseUrl;
  const MyApp({super.key, required this.apiBaseUrl});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(ApiService())),
      ],
      child: MaterialApp(
        title: 'AppCar Araluka',
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
        routes: {
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}
