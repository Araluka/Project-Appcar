import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'car_list_page.dart';

class SearchFormPage extends StatefulWidget {
  final String token; // ✅ รับ token มาจาก main
  const SearchFormPage({super.key, required this.token});

  @override
  State<SearchFormPage> createState() => _SearchFormPageState();
}

class _SearchFormPageState extends State<SearchFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _location;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _locations = ['Suvarnabhumi', 'Don Mueang', 'Bangkok'];
  final DateFormat _formatter = DateFormat('dd MMM yyyy');

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กรุณาเลือกวันเริ่มต้นและสิ้นสุด")),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CarListPage(
            token: widget.token, // ✅ ตอนนี้ไม่แดงแล้ว
            location: _location!,
            startDate: _startDate!,
            endDate: _endDate!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Cars"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _location,
                items: _locations
                    .map((loc) => DropdownMenuItem(
                          value: loc,
                          child: Text(loc),
                        ))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() {
                    _location = val;
                  });
                },
                validator: (val) =>
                    val == null ? "Please select a location" : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(context, true),
                      child: Text(_startDate == null
                          ? "Pick Start Date"
                          : _formatter.format(_startDate!)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(context, false),
                      child: Text(_endDate == null
                          ? "Pick End Date"
                          : _formatter.format(_endDate!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text("Search"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
