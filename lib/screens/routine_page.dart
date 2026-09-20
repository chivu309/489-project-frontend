import 'package:flutter/material.dart';

// A single checklist item (e.g. "Cleanser") with its icon and checked state
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

  // Whether the user has started today's log yet — controls whether we
  // show the "Every day routine" prompt or the actual checklist
  bool _hasLoggedToday = false;

  // Morning routine items — pre-checked to match your mockup ("completed")
  final List<RoutineItem> _morningItems = [
    RoutineItem(name: 'Cleanser', icon: Icons.water_drop_outlined, isChecked: true),
    RoutineItem(name: 'Moisturizer', icon: Icons.spa_outlined, isChecked: true),
    RoutineItem(name: 'Sunscreen', icon: Icons.wb_sunny_outlined, isChecked: true),
  ];

  // Evening routine items — 1 of 3 checked, matching your mockup
  final List<RoutineItem> _eveningItems = [
    RoutineItem(name: 'Cleanser', icon: Icons.water_drop_outlined, isChecked: true),
    RoutineItem(name: 'Serum', icon: Icons.opacity_outlined, isChecked: false),
    RoutineItem(name: 'Moisturizer', icon: Icons.spa_outlined, isChecked: false),
  ];

  // Static product list for the Products tab
  final List<Map<String, dynamic>> _products = [
    {'name': 'Brand name', 'icon': Icons.science_outlined},
    {'name': 'Brand name', 'icon': Icons.account_balance_wallet_outlined},
    {'name': 'Brand name', 'icon': Icons.local_drink_outlined},
    {'name': 'Brand name', 'icon': Icons.colorize_outlined},
  ];

  // How many items are checked, out of how many total, across both routines
  int get _totalCompleted =>
      _morningItems.where((i) => i.isChecked).length +
          _eveningItems.where((i) => i.isChecked).length;

  int get _totalSteps => _morningItems.length + _eveningItems.length;

  double get _progressFraction => _totalSteps == 0 ? 0 : _totalCompleted / _totalSteps;

  // Returns "completed" if every item in the list is checked,
  // otherwise "X of Y" (e.g. "1 of 3")
  String _badgeText(List<RoutineItem> items) {
    final checkedCount = items.where((i) => i.isChecked).length;
    if (checkedCount == items.length) return 'completed';
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
              child: SingleChildScrollView(
                child: _selectedTab == 0 ? _buildRoutineTab() : _buildProductsTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Header: title + "today" button ----------
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
        OutlinedButton.icon(
          onPressed: () {
            // TODO: hook up a real date picker later if needed
          },
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          label: const Text('today'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            side: const BorderSide(color: Colors.black26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
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

  // Routine page 1: prompt to start logging
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
              const Text('Update your every day routine',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              const Text(
                'Your skincare routine has been updated based on your latest skin analysis. Since skin can change over time and be affected by the environment, regular routine adjustments can help keep your skincare effective.',
                style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
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

  // Routine page 2: progress bar + morning/evening checklists
  Widget _buildChecklistState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            onPressed: () {
              // TODO: persist today's log (local storage or backend) later
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Routine log saved!')),
              );
            },
            child: const Text('Save Log'),
          ),
        ),
      ],
    );
  }

  // One routine card (Morning or Evening) with its checklist items
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
          Text(item.name),
        ],
      ),
    );
  }

  // ---------- Products tab content ----------
  Widget _buildProductsTab() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: _products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          final isLast = index == _products.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: [
                Icon(product['icon'] as IconData, size: 24),
                const SizedBox(width: 16),
                Text(product['name'] as String, style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}