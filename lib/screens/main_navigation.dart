import 'package:flutter/material.dart';
import 'package:skincare_ai_system/main.dart';
import 'home_page.dart';
import 'chatbot_page.dart';
import 'routine_page.dart';
import 'profile_page.dart';
import 'scan_screen.dart';
import 'scan_questions_page.dart';
import '../services/saved_routine_storage.dart';
import '../services/streak_service.dart';
import '../services/app_events.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onGoToRoutine: _goToRoutineTab),
      const ChatbotPage(),
      // Rebuilds RoutinePage (and reloads its data) whenever a new routine is saved
      ValueListenableBuilder<int>(
        valueListenable: SavedRoutineStorage.routineVersion,
        builder: (_, version, _) => RoutinePage(key: ValueKey(version)),
      ),
      // Rebuilds ProfilePage (reloads skin profile) after a scan updates it
      ValueListenableBuilder<int>(
        valueListenable: AppEvents.skinProfileVersion,
        builder: (_, version, _) => ProfilePage(
          key: ValueKey('profile_$version'),
          onGoToRoutine: _goToRoutineTab,
        ),
      ),
    ];

    // Load the streak once at start-up (used by Home card + nav badge)
    StreakService.refresh();
  }

  void _goToRoutineTab() {
    setState(() => _selectedIndex = 2);
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    // Refresh the streak whenever the user switches tabs,
    // so it updates after they Save Log on the Routine page.
    StreakService.refresh();
  }

  Future<void> _openCamera() async {
    final imagePaths = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => SkinScanScreen(cameras: cameras)),
    );
    if (!mounted) return;
    if (imagePaths != null && imagePaths.length == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanQuestionsPage(imagePaths: imagePaths),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 64,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(icon: Icons.home_outlined, label: 'Home', index: 0),
              _navItem(icon: Icons.chat_bubble_outline, label: 'Chat', index: 1),
              _cameraItem(),
              _navItem(
                icon: Icons.menu_book_outlined,
                label: 'Routine',
                index: 2,
                showStreakBadge: true,
              ),
              _navItem(icon: Icons.person_outline, label: 'Profile', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    bool showStreakBadge = false,
  }) {
    final bool isSelected = _selectedIndex == index;
    final Color color = isSelected ? const Color(0xFF4A5A3A) : Colors.black45;

    Widget iconWidget = Icon(icon, color: color, size: 24);

    if (showStreakBadge) {
      iconWidget = ValueListenableBuilder<int>(
        valueListenable: StreakService.currentStreak,
        builder: (_, streak, child) {
          if (streak <= 0) return child!; // no badge when there's no streak
          return Stack(
            clipBehavior: Clip.none,
            children: [
              child!,
              Positioned(
                top: -6,
                right: -18,
                child: _streakBadge(streak),
              ),
            ],
          );
        },
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _streakBadge(int streak) {
    return ValueListenableBuilder<bool>(
      valueListenable: StreakService.loggedToday,
      builder: (_, loggedToday, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          // Dark green when today is logged, orange to nudge when not yet
          color: loggedToday ? const Color(0xFF4A5A3A) : const Color(0xFFE8833A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Text(
          '🔥$streak',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _cameraItem() {
    return GestureDetector(
      onTap: _openCamera,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFD9E2CD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt_outlined,
                color: Color(0xFF4A5A3A), size: 20),
          ),
        ],
      ),
    );
  }
}