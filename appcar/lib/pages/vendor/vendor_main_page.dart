import 'package:flutter/material.dart';
import 'vendor_home_page.dart';
import 'vendor_car_list_page.dart';
import 'vendor_notifications_page.dart';
import 'vendor_profile_page.dart';

class VendorMainPage extends StatefulWidget {
  const VendorMainPage({super.key});

  @override
  State<VendorMainPage> createState() => _VendorMainPageState();
}

class _VendorMainPageState extends State<VendorMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    VendorHomePage(), // การจองของร้าน
    VendorCarListPage(), // รถของฉัน
    VendorNotificationsPage(), // การแจ้งเตือน
    VendorProfilePage(), // โปรไฟล์
  ];

  final List<String> _titles = const [
    "การจองของร้าน",
    "รถของฉัน",
    "การแจ้งเตือน",
    "โปรไฟล์",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ✅ เอาลูกศรย้อนกลับออก
        title: Text(_titles[_selectedIndex]),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // ✅ ให้แสดงครบ 4 tab
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: "การจอง",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: "รถของฉัน",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "การแจ้งเตือน",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "โปรไฟล์",
          ),
        ],
      ),
    );
  }
}
