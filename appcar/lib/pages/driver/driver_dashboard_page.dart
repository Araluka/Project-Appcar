import 'package:flutter/material.dart';

class DriverDashboardPage extends StatelessWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Dashboard")),
      body: const Center(
        child: Text("This is Driver Dashboard Page"),
      ),
    );
  }
}
