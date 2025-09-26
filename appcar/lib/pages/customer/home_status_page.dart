import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/token_store.dart';
import 'booking_detail_page.dart';

class HomeStatusPage extends StatefulWidget {
  final String token;
  const HomeStatusPage({super.key, required this.token});

  @override
  State<HomeStatusPage> createState() => _HomeStatusPageState();
}

class _HomeStatusPageState extends State<HomeStatusPage> {
  List<dynamic> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final token = await TokenStore.getToken();
      final data = await ApiService().getCustomerBookings(token!);
      setState(() {
        _bookings = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "โหลดข้อมูลการจองล้มเหลว: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ❌ ไม่มี AppBar แล้ว
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _bookings.isEmpty
                  ? const Center(child: Text("ยังไม่มีการจอง"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final b = _bookings[index];
                        return Card(
                          child: ListTile(
                            title: Text("Booking #${b['id']}"),
                            subtitle: Text("สถานะ: ${b['status']}"),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingDetailPage(
                                    bookingId: b['id'],
                                    token: widget.token,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
