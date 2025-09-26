import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/token_store.dart';
import 'vendor_car_form_page.dart'; // ใช้เพิ่มรถ
import 'car_detail_page.dart'; // ดู detail แบบ read-only

class VendorCarListPage extends StatefulWidget {
  const VendorCarListPage({super.key});

  @override
  State<VendorCarListPage> createState() => _VendorCarListPageState();
}

class _VendorCarListPageState extends State<VendorCarListPage> {
  List<dynamic> _cars = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMyCars();
  }

  Future<void> _fetchMyCars() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await TokenStore.getToken();
      final cars =
          await ApiService().getMyCars(token!); // ✅ ใช้เมธอด ApiService
      setState(() {
        _cars = cars;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "โหลดข้อมูลรถไม่สำเร็จ: $e";
        _loading = false;
      });
    }
  }

  Future<void> _deleteCar(int carId) async {
    final token = await TokenStore.getToken();
    try {
      await ApiService().deleteCar(carId, token!); // ✅ ใช้เมธอด ApiService
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ลบรถสำเร็จ")),
      );
      _fetchMyCars();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ลบรถไม่สำเร็จ: $e")),
      );
    }
  }

  Future<void> _updateCar(dynamic car, int index) async {
    final nameController = TextEditingController(text: car['name']);
    final licenseController = TextEditingController(text: car['license_plate']);
    final priceController =
        TextEditingController(text: car['price_per_day'].toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("แก้ไขรถ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "ชื่อรถ"),
            ),
            TextField(
              controller: licenseController,
              decoration: const InputDecoration(labelText: "ทะเบียน"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "ราคา/วัน"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () async {
              final token = await TokenStore.getToken();
              try {
                await ApiService().updateCar(
                  // ✅ ใช้เมธอด ApiService
                  car['id'],
                  {
                    "name": nameController.text,
                    "license_plate": licenseController.text,
                    "price_per_day": double.tryParse(priceController.text) ?? 0,
                    "image_url": car['image_url'], // คงรูปเดิม
                  },
                  token!,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("แก้ไขรถสำเร็จ")),
                );
                _fetchMyCars();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("แก้ไขรถไม่สำเร็จ: $e")),
                );
              }
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  void _goToAddCar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VendorCarFormPage()),
    );
    _fetchMyCars();
  }

  void _goToCarDetail(dynamic car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarDetailPage(car: car, isVendorView: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รถของฉัน"),
        leading: IconButton(
          icon: const Icon(Icons.add),
          onPressed: _goToAddCar,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchMyCars,
                  child: _cars.isEmpty
                      ? const Center(child: Text("ยังไม่มีรถในระบบ"))
                      : ListView.builder(
                          itemCount: _cars.length,
                          itemBuilder: (context, index) {
                            final car = _cars[index];
                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                leading: car['image_url'] != null
                                    ? Image.network(
                                        car['image_url'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.directions_car,
                                        size: 40),
                                title: Text(car['name'] ?? 'ไม่มีชื่อรถ'),
                                subtitle: Text(
                                  "ทะเบียน: ${car['license_plate'] ?? '-'}\nราคา: ${car['price_per_day']} บาท/วัน",
                                ),
                                onTap: () => _goToCarDetail(car),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => _updateCar(car, index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteCar(car['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
