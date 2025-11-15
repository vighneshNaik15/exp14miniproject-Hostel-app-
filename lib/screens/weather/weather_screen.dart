import 'package:flutter/material.dart';
import '../../services/weather_api.dart';
import '../../models/weather_model.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool isLoading = true;
  bool hasError = false;

  WeatherModel? weather;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    try {
      weather = await WeatherApi().getWeather();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f5f9),

      appBar: AppBar(
        title: const Text("Weather"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(
                  child: Text(
                    "Failed to fetch weather",
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                )
              : weatherContent(),
    );
  }

  Widget weatherContent() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // City Name
          Text(
            weather!.city,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Temperature
          Text(
            "${weather!.temperature}°C",
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),

          const SizedBox(height: 4),

          // Main Weather Condition
          Text(
            weather!.condition,
            style: TextStyle(
              fontSize: 20,
              color: Colors.blue.shade700,
            ),
          ),

          const SizedBox(height: 30),

          // Weather Info Cards Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              infoCard(
                icon: Icons.water_drop,
                label: "Humidity",
                value: "${weather!.humidity}%",
                color: Colors.blue.shade100,
                iconColor: Colors.blue,
              ),
              infoCard(
                icon: Icons.air,
                label: "Wind",
                value: "${weather!.windSpeed} km/h",
                color: Colors.purple.shade100,
                iconColor: Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Feels like card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.thermostat, size: 40, color: Colors.orange),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Feels Like",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    Text(
                      "${weather!.feelsLike}°C",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget infoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
