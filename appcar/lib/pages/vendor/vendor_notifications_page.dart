import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/token_store.dart';

class VendorNotificationsPage extends StatefulWidget {
  const VendorNotificationsPage({super.key});

  @override
  State<VendorNotificationsPage> createState() =>
      _VendorNotificationsPageState();
}

class _VendorNotificationsPageState extends State<VendorNotificationsPage> {
  List<dynamic> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final token = await TokenStore.getToken();
      final response = await ApiService().getMyNotifications(token!);
      setState(() {
        _notifications = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "โหลดการแจ้งเตือนล้มเหลว: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("การแจ้งเตือน"),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _notifications.isEmpty
                  ? const Center(child: Text("ยังไม่มีการแจ้งเตือน"))
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.notifications),
                            title: Text(n['title'] ?? 'ไม่ระบุหัวข้อ'),
                            subtitle: Text(n['message'] ?? ''),
                            trailing: Text(
                              n['created_at'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
