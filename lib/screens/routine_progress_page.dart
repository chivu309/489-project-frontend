import 'package:flutter/material.dart';
import '../services/routine_storage.dart';

class RoutineProgressPage extends StatefulWidget {
  const RoutineProgressPage({super.key});

  @override
  State<RoutineProgressPage> createState() => _RoutineProgressPageState();
}

class _RoutineProgressPageState extends State<RoutineProgressPage> {
  bool _isLoading = true;

  Set<DateTime> _activeDates = {};
  int _currentStreak = 0;
  int _longestStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final activeDates = await RoutineStorage.loadActiveDatesSet();
    final currentStreak = await RoutineStorage.calculateCurrentStreak();
    final longestStreak = await RoutineStorage.calculateLongestStreak();

    if (mounted) {
      setState(() {
        _activeDates = activeDates;
        _currentStreak = currentStreak;
        _longestStreak = longestStreak;
        _isLoading = false;
      });
    }
  }

  bool _isActive(DateTime date) {
    return _activeDates.any((d) =>
    d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Routine Progress', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeekSection(),
              const SizedBox(height: 20),
              _buildAlmostThereCard(),
              const SizedBox(height: 20),
              _buildStreakCards(),
              const SizedBox(height: 24),
              _buildMonthlyOverview(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- "This Week" strip ----------
  Widget _buildWeekSection() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Find this week's Monday
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('This Week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              '${_monthAbbrev(monday.month)} ${monday.day} - ${weekDays.last.day}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final date = weekDays[i];
            final isToday = _isSameDay(date, today);
            final isActive = _isActive(date);
            final isFuture = date.isAfter(today);

            return Column(
              children: [
                Text(dayLabels[i], style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 6),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? const Color(0xFF4A5A3A) : Colors.transparent,
                    border: Border.all(
                      color: isToday
                          ? const Color(0xFF4A5A3A)
                          : (isActive ? Colors.transparent : Colors.black26),
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : (isFuture ? Colors.black26 : Colors.black87),
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  // ---------- "Almost there!" progress card ----------
  Widget _buildAlmostThereCard() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    // Only count days from Monday up to today (can't have "missed" future days)
    int scheduledSoFar = 0;
    int completedSoFar = 0;
    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      if (date.isAfter(today)) break;
      scheduledSoFar++;
      if (_isActive(date)) completedSoFar++;
    }

    final percent = scheduledSoFar == 0 ? 0 : ((completedSoFar / scheduledSoFar) * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE3D5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: scheduledSoFar == 0 ? 0 : completedSoFar / scheduledSoFar,
                  strokeWidth: 6,
                  backgroundColor: Colors.white,
                  color: const Color(0xFF4A5A3A),
                ),
              ),
              Text('$percent%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Almost there!', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'You have completed $completedSoFar out of $scheduledSoFar skincare routines scheduled for this week.',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Streak cards ----------
  Widget _buildStreakCards() {
    return Row(
      children: [
        Expanded(
          child: _streakCard(
            icon: Icons.local_fire_department,
            iconColor: Colors.deepOrange,
            label: 'Current Streak',
            value: '$_currentStreak Days',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _streakCard(
            icon: Icons.emoji_events,
            iconColor: Colors.amber[700]!,
            label: 'Longest Streak',
            value: '$_longestStreak Days',
          ),
        ),
      ],
    );
  }

  Widget _streakCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ---------- Monthly calendar overview ----------
  Widget _buildMonthlyOverview() {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // weekday: 1 = Monday ... 7 = Sunday. Number of blank cells before day 1.
    final leadingBlanks = firstOfMonth.weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Monthly Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('${_monthAbbrev(now.month)} ${now.year}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => Expanded(
            child: Center(
              child: Text(d, style: const TextStyle(fontSize: 11, color: Colors.black45)),
            ),
          ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 10,
          ),
          itemCount: leadingBlanks + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox();

            final day = index - leadingBlanks + 1;
            final date = DateTime(now.year, now.month, day);
            final isActive = _isActive(date);

            return Column(
              children: [
                Text('$day', style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? const Color(0xFF4A5A3A) : Colors.transparent,
                    border: isActive ? null : Border.all(color: Colors.black26, width: 1),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _legendDot(filled: true),
            const SizedBox(width: 6),
            const Text('Routine Logged', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(width: 20),
            _legendDot(filled: false),
            const SizedBox(width: 6),
            const Text('Missed / Future', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  Widget _legendDot({required bool filled}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? const Color(0xFF4A5A3A) : Colors.transparent,
        border: filled ? null : Border.all(color: Colors.black26, width: 1),
      ),
    );
  }

  String _monthAbbrev(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}