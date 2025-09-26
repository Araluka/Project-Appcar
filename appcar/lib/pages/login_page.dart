import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/token_store.dart';
import 'signup_page.dart';
import 'package:appcar/pages/customer/customer_main_page.dart';
import 'vendor/vendor_main_page.dart';
import 'driver/driver_dashboard_page.dart';
import 'customer/search_form_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> response = await ApiService().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final String token = response['token'];
      final String role = response['role'];

      await TokenStore.saveToken(token);

      if (!mounted) return;

      Widget nextPage;
      if (role == 'customer') {
        nextPage = CustomerMainPage(token: token);
      } else if (role == 'vendor') {
        nextPage = const VendorMainPage(); // 👈 เด้งไปหน้า VendorMainPage
      } else if (role == 'driver') {
        nextPage = const DriverDashboardPage();
      } else {
        nextPage = SearchFormPage(token: token);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    } on DioException catch (e) {
      setState(() {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          _error = data['error']?.toString() ?? 'Login failed';
        } else if (data is String) {
          _error = data;
        } else {
          _error = 'Login failed';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: $e';
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
                const Icon(Icons.directions_car, size: 100),
                const SizedBox(height: 16),
                const Text(
                  "Car rental",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
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
                const SizedBox(height: 8),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("LOGIN"),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don’t have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupPage()),
                        );
                      },
                      child: const Text("Sign up now"),
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
