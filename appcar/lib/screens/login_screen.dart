// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('เข้าสู่ระบบ')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                TextFormField(
                  controller: _emailCtl,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'กรอกอีเมล' : null,
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
                                  .login(_emailCtl.text.trim(), _passCtl.text);
                              if (context.mounted) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) => const HomeScreen()),
                                );
                              }
                            } catch (e) {
                              setState(() => _error = '$e');
                            }
                          },
                    child: auth.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('เข้าสู่ระบบ'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
