import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/token_store.dart';
import '../../config/env.dart';

class BookingDetailPage extends StatefulWidget {
  final int bookingId;
  final String token;

  const BookingDetailPage({
    super.key,
    required this.bookingId,
    required this.token,
  });

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
      final response =
          await ApiService().getBookingDetail(widget.bookingId, widget.token);
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
      await ApiService().cancelBooking(widget.bookingId, widget.token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking cancelled successfully")));
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: (booking!['image_url'] != null &&
                                      booking!['image_url']
                                          .toString()
                                          .isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        "${Env.apiBaseUrl}${booking!['image_url']}",
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(
                                            Icons.directions_car,
                                            size: 40),
                                      ),
                                    )
                                  : const Icon(Icons.directions_car, size: 40),
                              title: Text(
                                booking!['car_name'] ?? '',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  "ร้าน: ${booking!['vendor_name'] ?? ''}"),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Timeline
                          _buildTimeline(
                            "จองรถ",
                            formatter.format(
                                DateTime.parse(booking!['created_at'])
                                    .toLocal()),
                            done: true,
                          ),
                          _buildTimeline(
                            "กำลังใช้งาน",
                            "${formatter.format(DateTime.parse(booking!['start_time']).toLocal())} - ${formatter.format(DateTime.parse(booking!['end_time']).toLocal())}",
                            current: booking!['status'] == 'confirmed',
                            done: booking!['status'] == 'completed',
                          ),
                          _buildTimeline(
                            "คืนรถ",
                            formatter.format(
                                DateTime.parse(booking!['end_time']).toLocal()),
                            current: booking!['status'] == 'pending_return',
                            done: booking!['status'] == 'completed',
                          ),
                          _buildTimeline(
                            "รีวิว",
                            "หลังใช้งาน",
                            current: booking!['status'] == 'completed',
                          ),

                          const SizedBox(height: 20),

                          // Cancel button
                          if (booking!['status'] == 'pending' ||
                              booking!['status'] == 'confirmed')
                            ElevatedButton(
                              onPressed: _cancelBooking,
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
