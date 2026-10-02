import 'package:supabase_flutter/supabase_flutter.dart';

class RoutineStorage {
  static final _client = Supabase.instance.client;

  // Returns a DateTime formatted as "YYYY-MM-DD"
  static String formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Returns today's date as "YYYY-MM-DD", matching Postgres's `date` type
  static String todayKey() => formatDateKey(DateTime.now());

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
  // used for streak calculation and the Routine Progress calendar view
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
        final dateStr = (log['log_date'] as String).substring(0, 10);
        activeDates.add(dateStr);
      }
    }

    final today = DateTime.now();
    final doneToday = activeDates.contains(todayKey());

    var checkDate = doneToday ? today : today.subtract(const Duration(days: 1));
    int streak = 0;

    while (activeDates.contains(formatDateKey(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // Returns the set of dates (normalized, no time component) where the
  // user completed at least one item — used for calendar/streak views
  static Future<Set<DateTime>> loadActiveDatesSet() async {
    final allLogs = await loadAllLogs();
    final dates = <DateTime>{};

    for (final log in allLogs) {
      final morning = List<String>.from(log['morning_completed'] ?? []);
      final evening = List<String>.from(log['evening_completed'] ?? []);
      if (morning.isNotEmpty || evening.isNotEmpty) {
        final parts = (log['log_date'] as String).split('-');
        dates.add(DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])));
      }
    }

    return dates;
  }

  // Longest-ever streak of consecutive active days (not just the current one)
  static Future<int> calculateLongestStreak() async {
    final dates = await loadActiveDatesSet();
    if (dates.isEmpty) return 0;

    final sorted = dates.toList()..sort();
    int longest = 1;
    int current = 1;

    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (diff > 1) {
        current = 1;
      }
    }

    return longest;
  }
}