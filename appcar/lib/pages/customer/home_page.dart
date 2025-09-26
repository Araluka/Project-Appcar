import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/env.dart';
import '../../models/booking.dart'; // ถ้าไม่มีไฟล์นี้ โค้ดก็ยังรันได้เพราะผมทำ fallback สำหรับ Map ให้
import '../../services/api_service.dart';
import '../common/notifications_page.dart'; // เผื่อเรียกจากที่อื่น
import 'booking_detail_page.dart';

class HomePage extends StatefulWidget {
  final String token;
  const HomePage({super.key, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _bookings = []; // รับได้ทั้ง Booking model หรือ Map

  final _dt = DateFormat('dd MMM yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      // ปัจจุบัน ApiService().getMyBookings คืนค่าเป็น List<Booking>
      final data = await ApiService().getCustomerBookings(widget.token);
      setState(() {
        _bookings = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'โหลดข้อมูลล้มเหลว: $e';
        _loading = false;
      });
    }
  }

  // ---------- Helpers: รองรับทั้ง Booking และ Map ----------
  int _idOf(dynamic b) {
    if (b is Booking) return b.id;
    return b['id'] ?? b['booking_id'] ?? 0;
  }

  String _statusOf(dynamic b) {
    if (b is Booking) return b.status ?? 'pending';
    return (b['status'] ?? 'pending').toString();
  }

  String _vendorNameOf(dynamic b) {
    return b is Map<String, dynamic>
        ? b['vendor_name']?.toString() ?? 'Vendor'
        : 'Vendor';
  }

  String _carNameOf(dynamic b) {
    return b is Map<String, dynamic>
        ? b['car_name']?.toString() ?? 'Car'
        : 'Car';
  }

  String? _imageUrlOf(dynamic b) {
    return b is Map<String, dynamic> ? b['image_url']?.toString() : null;
  }

  DateTime? _startOf(dynamic b) {
    if (b is Map<String, dynamic> && b['start_time'] != null) {
      return DateTime.tryParse(b['start_time'].toString());
    }
    return null;
  }

  DateTime? _endOf(dynamic b) {
    if (b is Map<String, dynamic> && b['end_time'] != null) {
      return DateTime.tryParse(b['end_time'].toString());
    }
    return null;
  }

  // ---------- UI helpers ----------
  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'confirmed':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = 'ยืนยันแล้ว';
        break;
      case 'pending':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
        label = 'รอดำเนินการ';
        break;
      case 'cancelled':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        label = 'ยกเลิกแล้ว';
        break;
      case 'completed':
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        label = 'เสร็จสิ้น';
        break;
      case 'no_driver_found':
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFEF6C00);
        label = 'ไม่มีคนขับ';
        break;
      default:
        bg = const Color(0xFFE0E0E0);
        fg = const Color(0xFF424242);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ❌ ไม่มี AppBar/ปุ่มกระดิ่งที่นี่แล้ว
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!))
            : _bookings.isEmpty
                ? const Center(child: Text('ยังไม่มีการจอง'))
                : RefreshIndicator(
                    onRefresh: _fetch,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final b = _bookings[index];
                        final id = _idOf(b);
                        final carName = _carNameOf(b);
                        final vendorName = _vendorNameOf(b);
                        final status = _statusOf(b);
                        final start = _startOf(b);
                        final end = _endOf(b);
                        final img = _imageUrlOf(b);

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingDetailPage(
                                  bookingId: id,
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFFF6F2F7), // โทนเดียวกับหน้า vendor
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE6E1E9)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // รูป
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: (img != null && img.isNotEmpty)
                                        ? Image.network(
                                            img.startsWith('http')
                                                ? img
                                                : '${Env.apiBaseUrl}$img',
                                            width: 96,
                                            height: 72,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              width: 96,
                                              height: 72,
                                              color: Colors.white,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                  Icons.directions_car,
                                                  size: 32),
                                            ),
                                          )
                                        : Container(
                                            width: 96,
                                            height: 72,
                                            color: Colors.white,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                                Icons.directions_car,
                                                size: 32),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  // รายละเอียด
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                carName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            _statusChip(status),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ร้าน: $vendorName (อัปเดต)',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.black54),
                                        ),
                                        if (start != null && end != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_dt.format(start)} → ${_dt.format(end)}',
                                            style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Row(
                                          children: const [
                                            Icon(Icons.chevron_right,
                                                size: 18,
                                                color: Colors.black45),
                                            SizedBox(width: 4),
                                            Text('ดูรายละเอียด',
                                                style: TextStyle(
                                                    color: Colors.black54)),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
  }
}
