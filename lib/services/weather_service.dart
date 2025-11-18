import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String _apiKey = 'bd5e378503939ddaee76f12ad7a97608'; // OpenWeather API key
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherModel> getCurrentWeather(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/weather?q=$city&appid=$_apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        return WeatherModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<ForecastModel>> get5DayForecast(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/forecast?q=$city&appid=$_apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        // Get one forecast per day (around noon)
        final dailyForecasts = <ForecastModel>[];
        String lastDate = '';
        
        for (var item in forecastList) {
          final date = item['dt_txt'].toString().split(' ')[0];
          if (date != lastDate && item['dt_txt'].toString().contains('12:00:00')) {
            dailyForecasts.add(ForecastModel.fromJson(item));
            lastDate = date;
            if (dailyForecasts.length >= 5) break;
          }
        }
        
        return dailyForecasts;
      } else {
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  String getWeatherAnimation(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'assets/animations/sunny.json';
      case 'clouds':
        return 'assets/animations/cloudy.json';
      case 'rain':
      case 'drizzle':
        return 'assets/animations/rain.json';
      case 'thunderstorm':
        return 'assets/animations/thunder.json';
      case 'snow':
        return 'assets/animations/snow.json';
      default:
        return 'assets/animations/cloudy.json';
    }
  }
}
