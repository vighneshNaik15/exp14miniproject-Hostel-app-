import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/holiday_model.dart';
import 'mock_holiday_data.dart';

class HolidayService {
  static const String _apiKey = 'YOUR_CALENDARIFIC_API_KEY'; // Replace with your API key
  static const String _baseUrl = 'https://calendarific.com/api/v2';
  static const bool _useMockData = true; // Set to false when you have a real API key

  Future<List<HolidayModel>> getHolidays({
    String country = 'IN',
    int? year,
  }) async {
    // Use mock data if enabled or if API key is not set
    if (_useMockData || _apiKey == 'YOUR_CALENDARIFIC_API_KEY') {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      return MockHolidayData.getMockHolidays();
    }

    try {
      final currentYear = year ?? DateTime.now().year;
      final response = await http.get(
        Uri.parse('$_baseUrl/holidays?api_key=$_apiKey&country=$country&year=$currentYear'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> holidays = data['response']['holidays'];
        return holidays.map((json) => HolidayModel.fromJson({
          'name': json['name'],
          'date': json['date']['iso'],
          'country': country,
          'public': json['primary_type'] == 'National holiday',
          'type': json['type'][0] ?? 'National',
        })).toList();
      } else {
        throw Exception('Failed to load holidays');
      }
    } catch (e) {
      // Fallback to mock data on error
      return MockHolidayData.getMockHolidays();
    }
  }

  List<HolidayModel> filterByType(List<HolidayModel> holidays, String type) {
    if (type == 'All') return holidays;
    return holidays.where((h) => h.type.toLowerCase().contains(type.toLowerCase())).toList();
  }

  List<HolidayModel> searchHolidays(List<HolidayModel> holidays, String query) {
    return holidays.where((h) => 
      h.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
