import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
          ],
        ),
      ),
    );
  }

  // ---------- Avatar + name + edit icon ----------
  Widget _buildAvatarSection() {
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
        const Text(
          'Sara', // placeholder for now — replaced with real data in Part 3
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ---------- Skin profile info card ----------
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

  // ---------- Menu list ----------
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
      onTap: () {
        // TODO: navigate to the relevant screen for each item
      },
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
}