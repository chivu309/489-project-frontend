import 'package:flutter/material.dart';
import 'home_page.dart';
import 'chatbot_page.dart';
import 'routine_page.dart';
import 'profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  // Tracks which tab is currently selected. 0 = Home.
  int _selectedIndex = 0;

  // The list of pages, in the same order as the bottom nav items.
  final List<Widget> _pages = const [
    HomePage(),
    ChatbotPage(),
    RoutinePage(),
    ProfilePage(),
  ];

  // Called whenever the user taps a nav item.
  void _onTabTapped(int index) {
    setState(() {
      // setState tells Flutter "something changed, please rebuild the UI"
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped, // runs every time a tab is tapped
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4A5A3A),
        unselectedItemColor: Colors.black45,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Routine'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}