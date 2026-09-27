import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'routine_progress_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? get _currentUser => Supabase.instance.client.auth.currentUser;

  Future<void> _signOut() async {
    // Show a confirmation dialog before actually signing out
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await Supabase.instance.client.auth.signOut();

    if (mounted) {
      // Clear the entire navigation stack and go back to LoginPage,
      // so the user can't press "back" and return to the app while logged out
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  void _handleMenuTap(String label) {
    switch (label) {
      case 'My Routine':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RoutineProgressPage()),
        );
        break;
    // Other items (Log My Routine, Privacy Policy, Reminder,
    // Terms and Conditions) not wired up yet — add cases here later
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatarSection(),
            const SizedBox(height: 24),
            _buildSkinProfileCard(),
            const SizedBox(height: 20),
            _buildMenuList(),
            const SizedBox(height: 20),
            _buildSignOutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final displayName = _currentUser?.email ?? 'Guest';

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: () {
              // TODO: navigate to edit profile screen
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ),
        Stack(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFDCE3D5),
              child: Icon(Icons.person, size: 50, color: Colors.black54),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCE3D5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          displayName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSkinProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Skin Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () {
                  // TODO: navigate to edit skin profile screen
                },
                child: const Text('Edit'),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildInfoRow('Skin Type', 'Sensitive'),
          const Divider(height: 20),
          _buildInfoRow('Skin concern', 'Acne'),
          const Divider(height: 20),
          _buildInfoRow('Allergies', 'None'),
          const Divider(height: 20),
          _buildInfoRow('Last skin analyses', '12/05/2026', icon: Icons.calendar_today_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
            ],
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMenuList() {
    final items = [
      'My Routine',
      'Log My Routine',
      'Privacy Policy',
      'Reminder',
      'Terms and Conditions',
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return _buildMenuItem(entry.value, isLast: isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(String label, {required bool isLast}) {
    return InkWell(
      onTap: () => _handleMenuTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            const Icon(Icons.chevron_right, size: 20, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  // ---------- Sign out button ----------
  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4A5A3A),
          side: const BorderSide(color: Color(0xFF4A5A3A)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _signOut,
        child: const Text('Log out'),
      ),
    );
  }
}