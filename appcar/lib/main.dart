import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String apiBaseUrl = "https://abcd.ngrok.io"; // หรือ dotenv สำหรับ Mobile

  runApp(MyApp(apiBaseUrl: apiBaseUrl));
}

class MyApp extends StatelessWidget {
  final String apiBaseUrl;
  const MyApp({super.key, required this.apiBaseUrl});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppCar Araluka',
      home: Scaffold(
        appBar: AppBar(title: Text("AppCar")),
        body: Center(child: Text("API Base URL: $apiBaseUrl")),
      ),
    );
  }
}
