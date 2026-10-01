import 'package:flutter/material.dart';
import 'package:skincare_ai_system/main.dart';
import 'home_page.dart';
import 'chatbot_page.dart';
import 'routine_page.dart';
import 'profile_page.dart';
import 'scan_screen.dart';
import 'scan_questions_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  /// Bumped whenever the Home tab is opened so Home reloads the streak
  final ValueNotifier<int> _homeRefresh = ValueNotifier<int>(0);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onGoToRoutine: _goToRoutineTab, refreshSignal: _homeRefresh),
      const ChatbotPage(),
      const RoutinePage(),
      ProfilePage(onGoToRoutine: _goToRoutineTab),
    ];
  }

  @override
  void dispose() {
    _homeRefresh.dispose();
    super.dispose();
  }

  void _goToRoutineTab() {
    setState(() => _selectedIndex = 2);
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) _homeRefresh.value++;
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
              _navItem(icon: Icons.menu_book_outlined, label: 'Routine', index: 2),
              _navItem(icon: Icons.person_outline, label: 'Profile', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      {required IconData icon, required String label, required int index}) {
    final bool isSelected = _selectedIndex == index;
    final Color color = isSelected ? const Color(0xFF4A5A3A) : Colors.black45;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
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