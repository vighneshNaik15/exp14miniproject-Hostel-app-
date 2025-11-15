import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherApi {
  final String apiKey = "997a2a39c5c0562f0ebbfc00a926efb5"; // 🔥 Your key
  final String city = "Goa"; // You can change this

  Future<WeatherModel> getWeather() async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        "Failed to load weather: ${response.statusCode}\n${response.body}",
      );
    }
  }
}
