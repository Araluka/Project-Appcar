import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/token_store.dart';

class VendorProfilePage extends StatefulWidget {
  const VendorProfilePage({super.key});

  @override
  State<VendorProfilePage> createState() => _VendorProfilePageState();
}

class _VendorProfilePageState extends State<VendorProfilePage> {
  Map<String, dynamic>? _profile;
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
        _profile = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "โหลดข้อมูลโปรไฟล์ล้มเหลว: $e";
        _loading = false;
      });
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("โปรไฟล์ร้านค้า"),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _profile == null
                  ? const Center(child: Text("ไม่พบข้อมูลโปรไฟล์"))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // ✅ Header card
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundColor: Colors.blue.shade100,
                                    child: const Icon(Icons.store,
                                        size: 40, color: Colors.blue),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _profile!['name'] ??
                                              'ไม่ทราบชื่อร้าน',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _profile!['email'] ?? '-',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ✅ ข้อมูลเพิ่มเติม
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildInfoRow(Icons.phone, "เบอร์โทร",
                                      _profile!['phone'] ?? '-'),
                                  _buildInfoRow(Icons.location_on, "ที่อยู่",
                                      _profile!['address'] ?? 'ไม่ระบุ'),
                                  _buildInfoRow(Icons.directions_car, "จำนวนรถ",
                                      "${_profile!['cars_count'] ?? 0} คัน"),
                                  _buildInfoRow(Icons.bookmark, "จำนวนการจอง",
                                      "${_profile!['bookings_count'] ?? 0} ครั้ง"),
                                  _buildInfoRow(Icons.star, "คะแนนรีวิว",
                                      "${_profile!['rating'] ?? '-'} / 5"),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ✅ ปุ่ม logout
                          ElevatedButton.icon(
                            onPressed: () {
                              TokenStore.clearToken();
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 0, 0),
                              minimumSize: const Size.fromHeight(50),
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text("ออกจากระบบ"),
                          )
                        ],
                      ),
                    ),
    );
  }
}
