import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/token_store.dart';
import 'customer/search_form_page.dart';
import 'login_page.dart';
import 'customer/customer_main_page.dart';
import 'vendor/vendor_main_page.dart';
import 'driver/driver_dashboard_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String _selectedRole = "customer"; // ✅ default role

  bool _loading = false;
  String? _error;

  Future<void> _signup() async {
    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _error = "Passwords do not match";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService().register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _phoneController.text.trim(),
        role: _selectedRole, // ✅ ส่ง role ไปด้วย
      );

      final String token = response['token'];
      final String role = response['role'];

      await TokenStore.saveToken(token);

      if (!mounted) return;

      Widget nextPage;
      if (role == 'customer') {
        nextPage = CustomerMainPage(token: token);
      } else if (role == 'vendor') {
        nextPage = const VendorMainPage();
      } else if (role == 'driver') {
        nextPage = const DriverDashboardPage();
      } else {
        nextPage = SearchFormPage(token: token);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    } catch (e) {
      setState(() {
        if (e is Map<String, dynamic>) {
          _error = e['message']?.toString() ??
              e['error']?.toString() ??
              'Sign up failed';
        } else {
          _error = 'Sign up failed: $e';
        }
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Sign up",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "Phone",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // ✅ เลือก role
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(
                        value: "customer", child: Text("Customer")),
                    DropdownMenuItem(value: "vendor", child: Text("Vendor")),
                    DropdownMenuItem(value: "driver", child: Text("Driver")),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedRole = val!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Role",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign up"),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text("Log In now"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
