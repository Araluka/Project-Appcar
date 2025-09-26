import 'package:flutter/material.dart';
import 'home_page.dart';
import 'search_form_page.dart';
import '../common/notifications_page.dart';
import '../common/profile_page.dart';

class CustomerMainPage extends StatefulWidget {
  final String token;
  const CustomerMainPage({super.key, required this.token});

  @override
  State<CustomerMainPage> createState() => _CustomerMainPageState();
}

class _CustomerMainPageState extends State<CustomerMainPage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(token: widget.token), // การจองของฉัน
      SearchFormPage(token: widget.token), // ค้นหารถ
      NotificationsPage(token: widget.token), // แจ้งเตือน
      ProfilePage(token: widget.token), // โปรไฟล์
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Booking"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              setState(() {
                _selectedIndex = 2; // กดไอคอน → ไปแท็บการแจ้งเตือน
              });
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: "การจองของฉัน",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "ค้นหา",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "แจ้งเตือน",
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
