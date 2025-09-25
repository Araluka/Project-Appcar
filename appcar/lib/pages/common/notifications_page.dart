import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../services/token_store.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notifications = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final token = await TokenStore.getToken();
      final data = await ApiService().getMyNotifications(token!);
      setState(() {
        _notifications = data;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data['error'] ?? 'โหลดการแจ้งเตือนล้มเหลว';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    return ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(n["title"] ?? ""),
                      subtitle: Text(n["message"] ?? ""),
                    );
                  },
                ),
    );
  }
}
