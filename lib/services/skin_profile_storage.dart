import 'package:supabase_flutter/supabase_flutter.dart';

class SkinProfileStorage {
  static final _client = Supabase.instance.client;

  // Loads the current user's skin profile, or null if not set up yet
  static Future<Map<String, dynamic>?> loadProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    return await _client
        .from('skin_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  // Saves (or updates) the current user's skin profile
  static Future<void> saveProfile({
    required String skinType,
    required String skinConcern,
    required String allergies,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No logged-in user');

    await _client.from('skin_profiles').upsert({
      'user_id': userId,
      'skin_type': skinType,
      'skin_concern': skinConcern,
      'allergies': allergies,
      'last_analysis_date': DateTime.now().toIso8601String().split('T').first,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }
}