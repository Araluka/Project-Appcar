// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก (ลูกค้า)')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(shrinkWrap: true, children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                TextFormField(
                  controller: _nameCtl,
                  decoration: const InputDecoration(
                      labelText: 'ชื่อ', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'กรอกชื่อ' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtl,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'กรอกอีเมล' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtl,
                  decoration: const InputDecoration(
                      labelText: 'เบอร์โทร', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'กรอกเบอร์โทร' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'รหัสผ่าน', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'กรอกรหัสผ่าน' : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _error = null);
                            try {
                              await context
                                  .read<AuthProvider>()
                                  .registerCustomer(
                                    name: _nameCtl.text.trim(),
                                    email: _emailCtl.text.trim(),
                                    phone: _phoneCtl.text.trim(),
                                    password: _passCtl.text,
                                  );
                              if (context.mounted)
                                Navigator.pop(context); // กลับไปล็อกอิน
                            } catch (e) {
                              setState(() => _error = '$e');
                            }
                          },
                    child: auth.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('สมัครสมาชิก'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
