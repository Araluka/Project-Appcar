import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/token_store.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final token = await TokenStore.getToken();
      final response = await ApiService().getProfile(token!);
      setState(() {
        profile = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "โหลดโปรไฟล์ล้มเหลว: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("โปรไฟล์"),
        automaticallyImplyLeading: false, // ไม่ให้มี back button
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : profile == null
                  ? const Center(child: Text("ไม่พบข้อมูลโปรไฟล์"))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("ชื่อ: ${profile!['name'] ?? ''}",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("อีเมล: ${profile!['email'] ?? ''}"),
                          const SizedBox(height: 8),
                          Text("เบอร์โทร: ${profile!['phone'] ?? ''}"),
                          const SizedBox(height: 8),
                          if (profile!['role'] == 'vendor')
                            Text("ร้าน: ${profile!['vendor_name'] ?? ''}"),
                          if (profile!['role'] == 'driver')
                            Text(
                                "พื้นที่บริการ: ${profile!['service_area'] ?? ''}"),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () async {
                              await TokenStore.clearToken();
                              if (!mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/login', (route) => false);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 0, 0)),
                            child: const Text("ออกจากระบบ"),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
