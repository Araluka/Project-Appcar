import 'package:flutter/material.dart';
import '../../models/car.dart';
import '../../services/api_service.dart';
import 'car_detail_page.dart';

class CarListPage extends StatefulWidget {
  final String location;
  final DateTime startDate;
  final DateTime endDate;

  const CarListPage({
    super.key,
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
      locationLat: coords['lat']!,
      locationLng: coords['lng']!,
      startTime: widget.startDate.toIso8601String(),
      endTime: widget.endDate.toIso8601String(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Cars"),
      ),
      body: FutureBuilder<List<Car>>(
        future: _cars,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
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
                      // รูปรถ + ชื่อ
                      Row(
                        children: [
                          car.imageUrl.isNotEmpty
                              ? Image.network(
                                  car.imageUrl,
                                  width: 120,
                                  height: 80,
                                  fit: BoxFit.cover,
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

                      // รายละเอียด
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.work, size: 18),
                          const SizedBox(width: 4),
                          Text("${car.bagSmall} Small bag"),
                          const SizedBox(width: 12),
                          Text("${car.bagLarge} Large bags"),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ราคา + ปุ่ม
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Price for ${widget.endDate.difference(widget.startDate).inDays} days:",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                "THB ${car.pricePerDay.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                "Free cancellation",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CarDetailPage(
                                    car: car,
                                    location: widget.location,
                                    startDate: widget.startDate,
                                    endDate: widget.endDate,
                                  ),
                                ),
                              );
                            },
                            child: const Text("view detail"),
                          ),
                        ],
                      )
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
