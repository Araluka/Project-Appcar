// lib/main.dart
import 'package:flutter/material.dart';
import 'register_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppCar',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: RegisterScreen(),
    );
  }
}
