import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/streak_service.dart';

/// Opens the routine calendar as a bottom sheet.
/// Usage: onPressed: () => showRoutineCalendar(context)
Future<void> showRoutineCalendar(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const RoutineCalendarSheet(),
  );
}

class RoutineCalendarSheet extends StatefulWidget {
  const RoutineCalendarSheet({super.key});

  @override
  State<RoutineCalendarSheet> createState() => _RoutineCalendarSheetState();
}

class _RoutineCalendarSheetState extends State<RoutineCalendarSheet> {
  static const _darkGreen = Color(0xFF4A5A3A);
  static const _sage = Color(0xFFDCE3D5);

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  late DateTime _visibleMonth; // always the 1st of a month
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = true;

  /// 'yyyy-MM-dd' -> {'morning': [...], 'evening': [...]}
  final Map<String, Map<String, List<String>>> _logs = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _loadLogs();
  }

  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<String> _toList(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : <String>[];

  Future<void> _loadLogs() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final rows = await client
          .from('routine_logs')
          .select('log_date, morning_completed, evening_completed')
          .eq('user_id', user.id)
          .order('log_date', ascending: false)
          .limit(400);

      for (final row in rows) {
        final morning = _toList(row['morning_completed']);
        final evening = _toList(row['evening_completed']);
        if (morning.isEmpty && evening.isEmpty) continue;
        _logs[row['log_date'].toString().substring(0, 10)] = {
          'morning': morning,
          'evening': evening,
        };
      }
    } catch (e) {
      debugPrint('Failed to load routine calendar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
  }

  int get _loggedDaysThisMonth => _logs.keys.where((k) {
    final prefix =
        '${_visibleMonth.year.toString().padLeft(4, '0')}-${_visibleMonth.month.toString().padLeft(2, '0')}';
    return k.startsWith(prefix);
  }).length;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        _visibleMonth.year == now.year && _visibleMonth.month == now.month;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title + streak
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Routine calendar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: StreakService.currentStreak,
                  builder: (_, streak, __) => Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _sage,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🔥 $streak-day streak',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Month switcher
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Expanded(
                  child: Text(
                    '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  // Don't allow browsing into future months
                  onPressed: isCurrentMonth ? null : () => _changeMonth(1),
                ),
              ],
            ),

            // Weekday labels
            Row(
              children: _weekdayLabels
                  .map((d) => Expanded(
                child: Center(
                  child: Text(d,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45)),
                ),
              ))
                  .toList(),
            ),
            const SizedBox(height: 6),

            _isLoading
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(),
            )
                : _buildMonthGrid(),

            const SizedBox(height: 8),
            Text(
              _isLoading
                  ? ''
                  : '$_loggedDaysThisMonth day${_loggedDaysThisMonth == 1 ? '' : 's'} logged this month',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            _buildDayDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGrid() {
    final firstDay = _visibleMonth;
    final daysInMonth = DateTime(firstDay.year, firstDay.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1; // Monday = 1
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (_, index) {
        final dayNumber = index - leadingBlanks + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(firstDay.year, firstDay.month, dayNumber);
        final isLogged = _logs.containsKey(_key(date));
        final isToday = _sameDay(date, today);
        final isSelected = _sameDay(date, _selectedDay);
        final isFuture = date.isAfter(today);

        return GestureDetector(
          onTap: isFuture ? null : () => setState(() => _selectedDay = date),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLogged ? _darkGreen : Colors.transparent,
              border: isSelected
                  ? Border.all(color: const Color(0xFFE8833A), width: 2)
                  : isToday
                  ? Border.all(color: _darkGreen, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isLogged
                    ? Colors.white
                    : isFuture
                    ? Colors.black26
                    : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayDetails() {
    final log = _logs[_key(_selectedDay)];
    final label =
        '${_selectedDay.day} ${_monthNames[_selectedDay.month - 1]} ${_selectedDay.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2ED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (log == null)
            const Text('No routine logged this day.',
                style: TextStyle(fontSize: 13, color: Colors.black54))
          else ...[
            _detailLine('🌞 Morning', log['morning']!),
            const SizedBox(height: 4),
            _detailLine('🌙 Evening', log['evening']!),
          ],
        ],
      ),
    );
  }

  Widget _detailLine(String heading, List<String> steps) {
    return Text(
      steps.isEmpty
          ? '$heading: not done'
          : '$heading: ${steps.join(', ')}',
      style: const TextStyle(fontSize: 13),
    );
  }
}