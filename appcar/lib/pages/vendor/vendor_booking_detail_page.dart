import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/token_store.dart';

class VendorBookingDetailPage extends StatefulWidget {
  final int bookingId;

  const VendorBookingDetailPage({super.key, required this.bookingId});

  @override
  State<VendorBookingDetailPage> createState() =>
      _VendorBookingDetailPageState();
}

class _VendorBookingDetailPageState extends State<VendorBookingDetailPage> {
  Map<String, dynamic>? booking;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final token = await TokenStore.getToken();
      final response = await ApiService()
          .getVendorBookingDetail(widget.bookingId, token!); // ✅ ใช้ของ vendor
      setState(() {
        booking = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "โหลดข้อมูลผิดพลาด: $e";
        _loading = false;
      });
    }
  }

  Future<void> _returnCar() async {
    try {
      final token = await TokenStore.getToken();
      await ApiService().returnBooking(widget.bookingId, token!);

      // ✅ update state ทันที
      setState(() {
        booking!['status'] = 'completed';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("คืนรถเรียบร้อยแล้ว ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("คืนรถล้มเหลว: $e")),
      );
    }
  }

  Widget _buildStep(String label, String? date,
      {bool done = false, bool current = false}) {
    Color color;
    IconData icon;

    if (done) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (current) {
      color = Colors.orange;
      icon = Icons.radio_button_checked;
    } else {
      color = Colors.grey;
      icon = Icons.radio_button_unchecked;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: color),
            Container(width: 2, height: 40, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 16)),
            if (date != null)
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
      appBar: AppBar(title: const Text("รายละเอียด Booking")),
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
                          // ✅ ข้อมูลรถ
                          Text(
                            "รถ: ${booking!['car_name']?.toString() ?? '-'}",
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          // ✅ ข้อมูลลูกค้า
                          Text("ลูกค้า: ${booking!['customer_name'] ?? '-'}"),
                          Text(
                              "เบอร์โทร: ${booking!['customer_phone'] ?? '-'}"),

                          const SizedBox(height: 12),

                          // ✅ ราคาและคนขับ
                          Text(
                            "ราคา: ฿${booking!['price_per_day']?.toString() ?? '-'} / วัน",
                          ),
                          Text(
                            "คนขับ: ${(booking!['driver_required'] ?? 0) == 1 ? 'ต้องการ' : 'ไม่ต้องการ'}",
                          ),

                          const SizedBox(height: 16),

                          // ✅ Timeline
                          _buildStep(
                            "จองรถ",
                            booking!['created_at'] != null
                                ? formatter.format(DateTime.parse(
                                    booking!['created_at'].toString()))
                                : null,
                            done: true,
                          ),
                          _buildStep(
                            "กำลังใช้งาน",
                            (booking!['start_time'] != null &&
                                    booking!['end_time'] != null)
                                ? "${formatter.format(DateTime.parse(booking!['start_time'].toString()))} - ${formatter.format(DateTime.parse(booking!['end_time'].toString()))}"
                                : null,
                            current: booking!['status'] == 'confirmed',
                            done: booking!['status'] == 'completed',
                          ),
                          _buildStep(
                            "คืนรถ",
                            booking!['end_time'] != null
                                ? formatter.format(DateTime.parse(
                                    booking!['end_time'].toString()))
                                : null,
                            current: booking!['status'] == 'confirmed',
                            done: booking!['status'] == 'completed',
                          ),
                          _buildStep(
                            "รีวิว",
                            "หลังใช้งาน",
                            done: booking!['status'] == 'completed',
                          ),

                          const SizedBox(height: 30),

                          // ✅ ปุ่มคืนรถ
                          // ✅ ปุ่มคืนรถ
                          if (booking!['status'] == 'confirmed')
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  final token = await TokenStore.getToken();
                                  final result = await ApiService()
                                      .returnBooking(widget.bookingId, token!);

                                  setState(() {
                                    booking!['status'] =
                                        result['status'] ?? 'completed';
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(result['message'] ??
                                            "คืนรถเรียบร้อยแล้ว ✅")),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("คืนรถล้มเหลว: $e")),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child: const Text("คืนรถแล้ว"),
                            ),
                        ],
                      ),
                    ),
    );
  }
}
