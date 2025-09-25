import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/token_store.dart';

class BookingDetailPage extends StatefulWidget {
  final int bookingId;

  const BookingDetailPage({super.key, required this.bookingId});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  Map<String, dynamic>? booking;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetail();
  }

  Future<void> _fetchBookingDetail() async {
    try {
      final token = await TokenStore.getToken();
      final response =
          await ApiService().getBookingDetail(widget.bookingId, token!);
      setState(() {
        booking = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error loading booking: $e";
        _loading = false;
      });
    }
  }

  Future<void> _cancelBooking() async {
    try {
      final token = await TokenStore.getToken();
      await ApiService().cancelBooking(widget.bookingId, token!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Booking cancelled")));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Cancel failed: $e")));
    }
  }

  Widget _buildTimeline(String label, String date,
      {bool done = false, bool current = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              done
                  ? Icons.check_circle
                  : current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
              color: done
                  ? Colors.green
                  : current
                      ? Colors.orange
                      : Colors.grey,
            ),
            Container(
              width: 2,
              height: 40,
              color: Colors.grey.shade300,
            )
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text(date, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text("Booking Detail")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : booking == null
                  ? const Center(child: Text("ไม่พบข้อมูลการจอง"))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: ListTile(
                              leading:
                                  const Icon(Icons.directions_car, size: 40),
                              title: Text(booking!['car_name'] ?? ''),
                              subtitle:
                                  Text("ร้าน: ${booking!['vendor_name']}"),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTimeline(
                              "จองรถ",
                              formatter.format(
                                  DateTime.parse(booking!['created_at'])),
                              done: true),
                          _buildTimeline("กำลังใช้งาน",
                              "${formatter.format(DateTime.parse(booking!['start_time']))} - ${formatter.format(DateTime.parse(booking!['end_time']))}",
                              current: booking!['status'] == 'confirmed',
                              done: booking!['status'] == 'completed'),
                          _buildTimeline(
                              "คืนรถ",
                              formatter
                                  .format(DateTime.parse(booking!['end_time'])),
                              current: booking!['status'] == 'pending_return',
                              done: booking!['status'] == 'completed'),
                          _buildTimeline("รีวิว", "หลังใช้งาน",
                              current: booking!['status'] == 'completed'),
                          const SizedBox(height: 20),
                          if (booking!['status'] == 'pending' ||
                              booking!['status'] == 'confirmed')
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  final token = await TokenStore.getToken();
                                  await ApiService()
                                      .cancelBooking(widget.bookingId, token!);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Booking cancelled")));
                                  Navigator.pop(context, true);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text("Cancel failed: $e")));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text("ยกเลิกการจอง"),
                            ),
                        ],
                      ),
                    ),
    );
  }
}
