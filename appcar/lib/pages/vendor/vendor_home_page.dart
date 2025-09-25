import 'package:flutter/material.dart';

class VendorHomePage extends StatelessWidget {
  const VendorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vendor Home")),
      body: const Center(
        child: Text("This is Vendor Home Page"),
      ),
    );
  }
}
