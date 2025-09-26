import 'package:flutter/material.dart';
import '../../models/car.dart';
import '../../services/api_service.dart';
import '../../config/env.dart';
import 'car_detail_page.dart';

class CarListPage extends StatefulWidget {
  final String token;
  final String location;
  final DateTime startDate;
  final DateTime endDate;

  const CarListPage({
    super.key,
    required this.token,
    required this.location,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<CarListPage> createState() => _CarListPageState();
}

class _CarListPageState extends State<CarListPage> {
  late Future<List<Car>> _cars;

  final Map<String, Map<String, double>> mockLocations = {
    "Suvarnabhumi": {"lat": 13.693, "lng": 100.752},
    "Don Mueang": {"lat": 13.912, "lng": 100.604},
    "Bangkok": {"lat": 13.756, "lng": 100.501},
  };

  @override
  void initState() {
    super.initState();
    final coords = mockLocations[widget.location]!;
    _cars = ApiService().searchCars(
      token: widget.token, // ✅ ส่ง token ด้วย
      locationLat: coords['lat']!,
      locationLng: coords['lng']!,
      startTime: widget.startDate.toIso8601String(),
      endTime: widget.endDate.toIso8601String(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Cars")),
      body: FutureBuilder<List<Car>>(
        future: _cars,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No cars available"));
          }

          final cars = snapshot.data!;
          return ListView.builder(
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.black12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          car.imageUrl.isNotEmpty
                              ? Image.network(
                                  "${Env.apiBaseUrl}${car.imageUrl}",
                                  width: 120,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(
                                      Icons.directions_car,
                                      size: 60),
                                )
                              : const Icon(Icons.directions_car, size: 60),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              car.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.event_seat, size: 18),
                          const SizedBox(width: 4),
                          Text("${car.seats} seats"),
                          const SizedBox(width: 12),
                          const Icon(Icons.speed, size: 18),
                          const SizedBox(width: 4),
                          Text(car.transmission),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.work, size: 18),
                          const SizedBox(width: 4),
                          Text("${car.bagSmall} small bags"),
                          const SizedBox(width: 12),
                          Text("${car.bagLarge} large bags"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "฿${car.pricePerDay.toStringAsFixed(0)}/day",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CarDetailPage(
                                    token: widget.token, // ✅ ส่ง token ต่อ
                                    car: car,
                                    location: widget.location,
                                    startDate: widget.startDate,
                                    endDate: widget.endDate,
                                  ),
                                ),
                              );
                            },
                            child: const Text("View detail"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
