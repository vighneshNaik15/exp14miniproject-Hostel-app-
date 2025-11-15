import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/holiday_model.dart';

class HolidaysApi {
  final String apiKey = "BfFv0ExaLFTO9Z2GfUFvmasJn2PsEOOd";

  Future<List<HolidayModel>> getHolidays() async {
    const String country = "IN"; // INDIA
    const String year = "2024";

    final url = Uri.parse(
      "https://holidayapi.com/v1/holidays?pretty&key=BfFv0ExaLFTO9Z2GfUFvmasJn2PsEOOd&country=$country&year=$year",
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to load holidays");
    }

    final data = jsonDecode(response.body);

    // holidayapi.com returns: { holidays: [ {name,date,public} ] }
    final List holidaysJson = data["holidays"] ?? [];

    // Convert to List<HolidayModel>
    return holidaysJson
        .map((item) => HolidayModel.fromJson(item))
        .toList();
  }
}
