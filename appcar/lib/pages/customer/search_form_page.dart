import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'car_list_page.dart';

class SearchFormPage extends StatefulWidget {
  const SearchFormPage({super.key});

  @override
  State<SearchFormPage> createState() => _SearchFormPageState();
}

class _SearchFormPageState extends State<SearchFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _location;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _locations = ['Suvarnabhumi', 'Don Mueang', 'Bangkok'];

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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CarListPage(
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
      appBar: AppBar(title: const Text("Search Cars")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _location,
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
                          : _startDate.toString().split(' ')[0]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(context, false),
                      child: Text(_endDate == null
                          ? "Pick End Date"
                          : _endDate.toString().split(' ')[0]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text("Search"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
