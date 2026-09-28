import 'package:supabase_flutter/supabase_flutter.dart';

class SavedRoutineStorage {
  static final _client = Supabase.instance.client;

  // Saves a new routine and deactivates the user's previous one
  static Future<void> saveRoutine({
    required List<String> morningSteps,
    required List<String> eveningSteps,
    String? note,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No logged-in user');

    // Deactivate first, because the unique index allows only one active routine
    await _client
        .from('saved_routines')
        .update({'is_active': false})
        .eq('user_id', userId)
        .eq('is_active', true);

    await _client.from('saved_routines').insert({
      'user_id': userId,
      'morning_steps': morningSteps,
      'evening_steps': eveningSteps,
      'note': note,
      'is_active': true,
    });
  }

  // Returns the user's active routine, or null if they haven't saved one
  static Future<Map<String, dynamic>?> loadActiveRoutine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    return await _client
        .from('saved_routines')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();
  }
}