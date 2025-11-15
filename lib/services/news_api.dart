import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';

class NewsApi {
  final String apiKey = "YOUR_NEWS_API_KEY"; // put your key here

  Future<List<NewsArticle>> fetchNews() async {
    final url = Uri.parse(
      "https://newsapi.org/v2/top-headlines?country=in&apiKey=$apiKey",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List articles = data["articles"];

      return articles.map((e) => NewsArticle.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load news");
    }
  }
}
