import 'package:flutter/material.dart';
import 'vendor_home_page.dart';
import 'vendor_car_form_page.dart';
import '../common/notifications_page.dart';
import '../common/profile_page.dart';

class VendorMainPage extends StatefulWidget {
  const VendorMainPage({super.key});

  @override
  State<VendorMainPage> createState() => _VendorMainPageState();
}

class _VendorMainPageState extends State<VendorMainPage> {
  int _index = 0;

  final pages = [
    const VendorHomePage(),
    const VendorCarFormPage(),
    const NotificationsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: "Bookings"),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car), label: "My Cars"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "แจ้งเตือน"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "โปรไฟล์"),
        ],
      ),
    );
  }
}
