import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.68.59:8000';

  // Existing test function
  static Future<String> testConnection() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'];
      } else {
        return 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Connection failed: $e';
    }
  }

  // NEW: sends questionnaire answers to /assess and returns the response
  static Future<Map<String, dynamic>> submitSkinCheck({
    required bool isPregnant,
    required bool hasHealthConcern,
    required String ageGroup,
    required String mainConcern,
  }) async {
    final url = Uri.parse('$baseUrl/assess');

    try {
      final response = await http.post(
        url,
        // Tells the server we're sending JSON
        headers: {'Content-Type': 'application/json'},
        // Converts our Dart values into a JSON string matching
        // the SkinCheckInput shape defined in main.py
        body: jsonEncode({
          'is_pregnant': isPregnant,
          'has_health_concern': hasHealthConcern,
          'age_group': ageGroup,
          'main_concern': mainConcern,
        }),
      );

      if (response.statusCode == 200) {
        // Decode the JSON response into a Dart Map we can use
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // Server responded, but with an error (e.g. bad data)
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Network failure, timeout, server not reachable, etc.
      throw Exception('Failed to submit skin check: $e');
    }
  }
}