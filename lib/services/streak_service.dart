import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Single place that calculates the routine streak.
/// Home card and the nav-bar badge both listen to these notifiers,
/// so they always show the same number.
class StreakService {
  static final ValueNotifier<int> currentStreak = ValueNotifier<int>(0);
  static final ValueNotifier<bool> loggedToday = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  static bool _hasAnyStep(dynamic list) => list is List && list.isNotEmpty;

  /// Reloads the streak from Supabase routine_logs.
  static Future<void> refresh() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      currentStreak.value = 0;
      loggedToday.value = false;
      isLoading.value = false;
      return;
    }

    try {
      final rows = await client
          .from('routine_logs')
          .select('log_date, morning_completed, evening_completed')
          .eq('user_id', user.id)
          .order('log_date', ascending: false)
          .limit(400);

      // A day counts if at least one step was ticked
      final activeDays = <String>{};
      for (final row in rows) {
        if (_hasAnyStep(row['morning_completed']) ||
            _hasAnyStep(row['evening_completed'])) {
          activeDays.add(row['log_date'].toString().substring(0, 10));
        }
      }

      final today = DateTime.now();
      final doneToday = activeDays.contains(_dateKey(today));

      // Streak still counts if today isn't logged yet (day isn't over)
      var day = doneToday ? today : today.subtract(const Duration(days: 1));
      var streak = 0;
      while (activeDays.contains(_dateKey(day))) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      }

      currentStreak.value = streak;
      loggedToday.value = doneToday;
    } catch (e) {
      debugPrint('Failed to load streak: $e');
    } finally {
      isLoading.value = false;
    }
  }
}