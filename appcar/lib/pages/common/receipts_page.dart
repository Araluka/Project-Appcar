import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../services/token_store.dart';

class ReceiptsPage extends StatefulWidget {
  const ReceiptsPage({super.key});

  @override
  State<ReceiptsPage> createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends State<ReceiptsPage> {
  List<dynamic> _receipts = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchReceipts();
  }

  Future<void> _fetchReceipts() async {
    try {
      final token = await TokenStore.getToken();
      final data = await ApiService().getMyReceipts(token!);
      setState(() {
        _receipts = data;
      });
    } on DioError catch (e) {
      setState(() {
        _error = e.response?.data['error'] ?? 'โหลดใบเสร็จล้มเหลว';
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
      appBar: AppBar(title: const Text("Receipts")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  itemCount: _receipts.length,
                  itemBuilder: (context, index) {
                    final r = _receipts[index];
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: const Icon(Icons.receipt),
                        title: Text("Receipt #${r["id"]}"),
                        subtitle: Text("Date: ${r["created_at"]}"),
                        trailing: Text(
                          "฿${r["amount"]}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
