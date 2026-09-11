import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://Quynhs-MacBook-Pro.local:8000';

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

  // Sends questionnaire answers to /assess and returns the response
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'is_pregnant': isPregnant,
          'has_health_concern': hasHealthConcern,
          'age_group': ageGroup,
          'main_concern': mainConcern,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to submit skin check: $e');
    }
  }

  // NEW: sends a free-form chat message + history to /chat and returns the response
  static Future<Map<String, dynamic>> sendChatMessage({
    required List<Map<String, String>> conversationHistory,
    required String latestMessage,
  }) async {
    final url = Uri.parse('$baseUrl/chat');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conversation_history': conversationHistory,
          'latest_message': latestMessage,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to send chat message: $e');
    }
  }
}