import 'package:flutter/material.dart';
import '../services/routine_storage.dart';
import '../services/saved_routine_storage.dart';
import 'routine_calendar_sheet.dart';

// A single checklist item (e.g. "Gentle cleanser") with its icon and checked state
class RoutineItem {
  final String name;
  final IconData icon;
  bool isChecked;
  RoutineItem({required this.name, required this.icon, this.isChecked = false});
}

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  // 0 = Routine tab, 1 = Products tab
  int _selectedTab = 0;

  // Whether the user has started today's log yet
  bool _hasLoggedToday = false;

  bool _isLoadingProgress = true;

  // True when the checklist comes from the user's saved AI routine,
  // false when we're showing the default steps
  bool _usingSavedRoutine = false;

  List<RoutineItem> _morningItems = _defaultMorning();
  List<RoutineItem> _eveningItems = _defaultEvening();

  // ---------- Default steps, used when no routine has been saved ----------
  static List<RoutineItem> _defaultMorning() => [
    RoutineItem(name: 'Cleanser', icon: Icons.water_drop_outlined),
    RoutineItem(name: 'Moisturizer', icon: Icons.spa_outlined),
    RoutineItem(name: 'Sunscreen', icon: Icons.wb_sunny_outlined),
  ];

  static List<RoutineItem> _defaultEvening() => [
    RoutineItem(name: 'Cleanser', icon: Icons.water_drop_outlined),
    RoutineItem(name: 'Serum', icon: Icons.opacity_outlined),
    RoutineItem(name: 'Moisturizer', icon: Icons.spa_outlined),
  ];

  // Picks an icon from keywords in the step text, since AI steps are free text
  IconData _iconFor(String step) {
    final s = step.toLowerCase();
    if (s.contains('cleans') || s.contains('wash')) return Icons.water_drop_outlined;
    if (s.contains('spf') || s.contains('sunscreen') || s.contains('sun')) return Icons.wb_sunny_outlined;
    if (s.contains('moisture') || s.contains('cream') || s.contains('lotion')) return Icons.spa_outlined;
    if (s.contains('serum') || s.contains('acid') || s.contains('niacinamide')) return Icons.opacity_outlined;
    if (s.contains('toner')) return Icons.blur_on_outlined;
    return Icons.check_circle_outline;
  }

  List<RoutineItem> _itemsFromSteps(List<String> steps) {
    return steps
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => RoutineItem(name: s, icon: _iconFor(s)))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Loads the saved routine (if any), then today's log, and applies both
  Future<void> _load() async {
    try {
      final saved = await SavedRoutineStorage.loadActiveRoutine();
      final todayLog = await RoutineStorage.loadTodayLog();

      var morning = _defaultMorning();
      var evening = _defaultEvening();
      var usingSaved = false;

      if (saved != null) {
        final savedMorning = _itemsFromSteps(List<String>.from(saved['morning_steps'] ?? []));
        final savedEvening = _itemsFromSteps(List<String>.from(saved['evening_steps'] ?? []));
        if (savedMorning.isNotEmpty) morning = savedMorning;
        if (savedEvening.isNotEmpty) evening = savedEvening;
        usingSaved = savedMorning.isNotEmpty || savedEvening.isNotEmpty;
      }

      var hasLogged = false;
      if (todayLog != null) {
        final morningDone = List<String>.from(todayLog['morning_completed'] ?? []);
        final eveningDone = List<String>.from(todayLog['evening_completed'] ?? []);
        for (final item in morning) {
          item.isChecked = morningDone.contains(item.name);
        }
        for (final item in evening) {
          item.isChecked = eveningDone.contains(item.name);
        }
        hasLogged = true;
      }

      if (mounted) {
        setState(() {
          _morningItems = morning;
          _eveningItems = evening;
          _usingSavedRoutine = usingSaved;
          _hasLoggedToday = hasLogged || _hasLoggedToday;
        });
      }
    } catch (e) {
      debugPrint('Failed to load routine: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProgress = false);
    }
  }

  int get _totalCompleted =>
      _morningItems.where((i) => i.isChecked).length +
          _eveningItems.where((i) => i.isChecked).length;

  int get _totalSteps => _morningItems.length + _eveningItems.length;

  double get _progressFraction => _totalSteps == 0 ? 0 : _totalCompleted / _totalSteps;

  String _badgeText(List<RoutineItem> items) {
    final checkedCount = items.where((i) => i.isChecked).length;
    if (items.isNotEmpty && checkedCount == items.length) return 'completed';
    return '$checkedCount of ${items.length}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildTabSelector(),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoadingProgress
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                // Pull down to reload after saving a new routine in the chat
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _selectedTab == 0 ? _buildRoutineTab() : _buildProductsTab(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Header ----------
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log routine', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Track your skincare steps today',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Reload my routine',
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 22),
            ),
            OutlinedButton.icon(
              onPressed: () => showRoutineCalendar(context),
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: const Text('today'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black26),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------- Tab selector: Routine / Products ----------
  Widget _buildTabSelector() {
    return Row(
      children: [
        _tabButton('Routine', 0),
        const SizedBox(width: 12),
        _tabButton('Products', 1),
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            decoration: isSelected ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }

  // ---------- Routine tab content ----------
  Widget _buildRoutineTab() {
    if (!_hasLoggedToday) {
      return _buildBeforeLogState();
    }
    return _buildChecklistState();
  }

  Widget _buildBeforeLogState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Every day routine',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFDCE3D5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _usingSavedRoutine ? 'Your saved routine is ready' : 'Update your every day routine',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                _usingSavedRoutine
                    ? 'Tick off each step as you complete it today. Your progress feeds your streak.'
                    : 'You have not saved a routine yet. Chat with Glow and tap "Save this routine", or log the default steps for now.',
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A5A3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => setState(() => _hasLoggedToday = true),
                  child: const Text('Log routine'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _usingSavedRoutine ? 'Using your saved routine' : 'Using the default steps',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),

        // Progress bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Today's progress", style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${(_progressFraction * 100).round()}%'),
                ],
              ),
              const SizedBox(height: 4),
              Text('$_totalCompleted out of $_totalSteps steps completed',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progressFraction,
                  minHeight: 8,
                  backgroundColor: Colors.black12,
                  color: const Color(0xFF4A5A3A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildRoutineCard(
          title: 'Morning Routine',
          icon: Icons.wb_sunny_outlined,
          items: _morningItems,
        ),
        const SizedBox(height: 16),
        _buildRoutineCard(
          title: 'Evening Routine',
          icon: Icons.nightlight_outlined,
          items: _eveningItems,
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A5A3A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              try {
                await RoutineStorage.saveTodayLog(
                  completedMorning: _morningItems.where((i) => i.isChecked).map((i) => i.name).toList(),
                  completedEvening: _eveningItems.where((i) => i.isChecked).map((i) => i.name).toList(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Routine log saved!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not save your log. Please try again.')),
                  );
                }
                debugPrint('Save log error: $e');
              }
            },
            child: const Text('Save Log'),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineCard({
    required String title,
    required IconData icon,
    required List<RoutineItem> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_badgeText(items), style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => _buildChecklistRow(item)),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(RoutineItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => item.isChecked = !item.isChecked),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: item.isChecked ? const Color(0xFF4A5A3A) : Colors.white,
                border: Border.all(color: item.isChecked ? const Color(0xFF4A5A3A) : Colors.black26),
                borderRadius: BorderRadius.circular(5),
              ),
              child: item.isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Icon(item.icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          // Expanded so long AI step text wraps instead of overflowing
          Expanded(child: Text(item.name)),
        ],
      ),
    );
  }

  // ---------- Products tab content (hasn't done) ----------
  Widget _buildProductsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.black26),
          const SizedBox(height: 16),
          const Text(
            'Product tracking coming soon',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "We're working on letting you save and track the products in your routine.",
            style: TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}