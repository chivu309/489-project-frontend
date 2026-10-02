import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  /// Pings the backend so Render starts waking up from sleep.
  /// Fire-and-forget: never throws, never blocks the UI.
  static Future<void> wakeUp() async {
    try {
      await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 60));
      debugPrint('Backend is awake');
    } catch (e) {
      debugPrint('Backend wake-up ping failed (will retry on next request): $e');
    }
  }

  static Future<Map<String, dynamic>> sendChatMessage({
    required List<Map<String, String>> conversationHistory,
    required String latestMessage,
    bool alreadyAssessed = false,
    String? skinType,
    String? allergies,
  }) async {
    final url = Uri.parse('$baseUrl/chat');

    try {
      final response = await http
          .post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conversation_history': conversationHistory,
          'latest_message': latestMessage,
          'already_assessed': alreadyAssessed,
          'skin_type': skinType,
          'allergies': allergies,
        }),
      )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to send chat message: $e');
    }
  }

  static Future<Map<String, dynamic>> assessScan({
    required String imagePath,
    required bool isPregnant,
    required bool hasHealthConcern,
    required String ageGroup,
    required String mainConcern,
    required String skinCondition,
    required String rednessHistory,
  }) async {
    final url = Uri.parse('$baseUrl/assess-scan');

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['is_pregnant'] = isPregnant.toString()
        ..fields['has_health_concern'] = hasHealthConcern.toString()
        ..fields['age_group'] = ageGroup
        ..fields['main_concern'] = mainConcern
        ..fields['skin_condition'] = skinCondition
        ..fields['redness_history'] = rednessHistory
        ..files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse =
      await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to assess scan: $e');
    }
  }
}