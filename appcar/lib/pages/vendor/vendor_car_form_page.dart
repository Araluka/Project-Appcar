import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/token_store.dart';

class VendorCarFormPage extends StatefulWidget {
  const VendorCarFormPage({super.key});

  @override
  State<VendorCarFormPage> createState() => _VendorCarFormPageState();
}

class _VendorCarFormPageState extends State<VendorCarFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _transmissionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _submitCar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await TokenStore.getToken();
      await ApiService().addCar({
        "name": _nameController.text.trim(),
        "license_plate": _licenseController.text.trim(),
        "seats": int.tryParse(_seatsController.text.trim()) ?? 0,
        "price_per_day": double.tryParse(_priceController.text.trim()) ?? 0,
        "transmission": _transmissionController.text.trim(),
        "image_url": _imageUrlController.text.trim().isEmpty
            ? "/uploads/default_car.png" // ✅ ถ้าไม่ได้ใส่รูป ใช้ default
            : _imageUrlController.text.trim(),
      }, token!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เพิ่มรถเรียบร้อย")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = "Unexpected error: $e";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เพิ่มรถของฉัน")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ช่องกรอก URL รูปรถ
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: "URL รูปรถ (ใส่ http... หรือปล่อยว่าง)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ชื่อรถ
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "ชื่อรถ",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "กรอกชื่อรถ" : null,
              ),
              const SizedBox(height: 12),

              // ทะเบียนรถ
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: "ทะเบียนรถ",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "กรอกทะเบียนรถ" : null,
              ),
              const SizedBox(height: 12),

              // จำนวนที่นั่ง
              TextFormField(
                controller: _seatsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "จำนวนที่นั่ง",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "กรอกจำนวนที่นั่ง" : null,
              ),
              const SizedBox(height: 12),

              // ระบบเกียร์
              TextFormField(
                controller: _transmissionController,
                decoration: const InputDecoration(
                  labelText: "ระบบเกียร์",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "กรอกเกียร์" : null,
              ),
              const SizedBox(height: 12),

              // ราคา/วัน
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "ราคา/วัน",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "กรอกราคา/วัน" : null,
              ),
              const SizedBox(height: 20),

              if (_error != null)
                Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14)),
              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: _loading ? null : _submitCar,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("บันทึกรถ"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
