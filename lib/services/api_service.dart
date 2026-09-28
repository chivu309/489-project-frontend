import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://skincarebackend-nkd8.onrender.com';

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

  // Sends a free-form chat message + history to /chat
  static Future<Map<String, dynamic>> sendChatMessage({
    required List<Map<String, String>> conversationHistory,
    required String latestMessage,
    bool alreadyAssessed = false,
  }) async {
    final url = Uri.parse('$baseUrl/chat');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conversation_history': conversationHistory,
          'latest_message': latestMessage,
          'already_assessed': alreadyAssessed,
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