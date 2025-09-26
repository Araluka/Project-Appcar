import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/car.dart';
import '../../config/env.dart';
import 'booking_page.dart';

class CarDetailPage extends StatelessWidget {
  final String token;
  final Car car;
  final String location;
  final DateTime startDate;
  final DateTime endDate;

  const CarDetailPage({
    super.key,
    required this.token, // ✅ ใส่ comma ตรงนี้
    required this.car,
    required this.location,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text("Car rental")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ ใช้ location และเวลาเลือกจริง
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$location\n${formatter.format(startDate)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                  Text(
                    "$location\n${formatter.format(endDate)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ✅ รายละเอียดรถ
            const Text("Detail",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    car.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  car.imageUrl.isNotEmpty
                      ? Image.network(
                          "${Env.apiBaseUrl}${car.imageUrl}", // ✅ ใช้พาธเต็มจาก backend
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.directions_car, size: 120),
                        )
                      : const Icon(Icons.directions_car, size: 120),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.event_seat, size: 18),
                    const SizedBox(width: 6),
                    Text("${car.seats} seats"),
                  ]),
                  Row(children: [
                    const Icon(Icons.speed, size: 18),
                    const SizedBox(width: 6),
                    Text(car.transmission),
                  ]),
                  Row(children: [
                    const Icon(Icons.work, size: 18),
                    const SizedBox(width: 6),
                    Text("${car.bagSmall} Small bag"),
                  ]),
                  Row(children: [
                    const Icon(Icons.work_outline, size: 18),
                    const SizedBox(width: 6),
                    Text("${car.bagLarge} Large bags"),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Great choice
            const Text("Great choice!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _CheckItem("คะแนนจากลูกค้า: 8.5 เต็ม 10"),
                _CheckItem("รอคิวน้อย"),
                _CheckItem("ค้นหารถได้ง่าย"),
                _CheckItem("ยกเลิกได้โดยไม่มีค่าใช้จ่าย"),
              ],
            ),
            const SizedBox(height: 20),

            // ✅ Pick-up checklist
            const Text("Your pick-up checklist",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _ChecklistSection(
              icon: Icons.access_time,
              title: "มาถึงตรงเวลา",
              description:
                  "ควรมาตามเวลาที่คุณเลือกไว้ในการจอง\nหากมาสาย รถอาจถูกปล่อยให้ลูกค้าคนอื่น",
            ),
            const Divider(),
            _ChecklistSection(
              icon: Icons.credit_card,
              title: "สิ่งที่ต้องนำมาติดต่อรับรถ",
              description: "- หนังสือเดินทางหรือบัตรประชาชน\n"
                  "- ใบขับขี่ของผู้ขับขี่\n"
                  "- บัตรเครดิตที่เป็นชื่อของผู้ขับขี่หลัก",
            ),
            const Divider(),
            _ChecklistSection(
              icon: Icons.security,
              title: "เงินประกันที่สามารถขอคืนได้",
              description:
                  "เมื่อคุณรับรถ ผู้เช่าต้องชำระเงินมัดจำอย่างน้อย 10,000 บาท\n"
                  "โดยใช้บัตรเครดิตเท่านั้น เงินนี้จะถูกคืนหลังส่งคืนรถ",
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingPage(
                  token: token, // ✅ ส่ง token ต่อไป
                  car: car,
                  startDate: startDate,
                  endDate: endDate,
                ),
              ),
            );
          },
          child: const Text("book now"),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;
  const _CheckItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 18),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

class _ChecklistSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ChecklistSection({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(description),
      ],
    );
  }
}
