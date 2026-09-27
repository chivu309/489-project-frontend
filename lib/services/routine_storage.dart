import 'package:supabase_flutter/supabase_flutter.dart';

class RoutineStorage {
  static final _client = Supabase.instance.client;

  // Returns today's date as "YYYY-MM-DD", matching Postgres's `date` type
  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Loads today's log for the current user, or null if none exists yet
  static Future<Map<String, dynamic>?> loadTodayLog() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('routine_logs')
        .select()
        .eq('user_id', userId)
        .eq('log_date', todayKey())
        .maybeSingle();

    return response;
  }

  // Saves (or updates) today's log for the current user.
  // Uses upsert with the unique (user_id, log_date) constraint so
  // re-saving the same day updates the existing row instead of erroring.
  static Future<void> saveTodayLog({
    required List<String> completedMorning,
    required List<String> completedEvening,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No logged-in user');

    await _client.from('routine_logs').upsert({
      'user_id': userId,
      'log_date': todayKey(),
      'morning_completed': completedMorning,
      'evening_completed': completedEvening,
    }, onConflict: 'user_id,log_date');
  }

  // Loads ALL of this user's logs, ordered by most recent first —
  // used for streak calculation and a future Routine Progress calendar view
  static Future<List<Map<String, dynamic>>> loadAllLogs() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('routine_logs')
        .select()
        .eq('user_id', userId)
        .order('log_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Calculates the current streak: consecutive days (ending today or
  // yesterday) where the user completed at least one item
  static Future<int> calculateCurrentStreak() async {
    final allLogs = await loadAllLogs();
    if (allLogs.isEmpty) return 0;

    final activeDates = <String>{};
    for (final log in allLogs) {
      final morning = List<String>.from(log['morning_completed'] ?? []);
      final evening = List<String>.from(log['evening_completed'] ?? []);
      if (morning.isNotEmpty || evening.isNotEmpty) {
        activeDates.add(log['log_date'] as String);
      }
    }

    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (true) {
      final key = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (!activeDates.contains(key)) break;
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }
}