import 'package:flutter/material.dart';
import '../services/saved_routine_storage.dart';
import 'routine_progress_page.dart';

class MyRoutinePage extends StatefulWidget {
  // Called when the user taps "Log today's routine" (switches to the Routine tab)
  final VoidCallback? onLogRoutine;
  const MyRoutinePage({super.key, this.onLogRoutine});

  @override
  State<MyRoutinePage> createState() => _MyRoutinePageState();
}

class _MyRoutinePageState extends State<MyRoutinePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _routine;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final routine = await SavedRoutineStorage.loadActiveRoutine();
      if (mounted) setState(() => _routine = routine);
    } catch (e) {
      debugPrint('Failed to load saved routine: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _savedOnText() {
    final created = DateTime.tryParse(_routine?['created_at'] ?? '')?.toLocal();
    if (created == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Saved on ${created.day} ${months[created.month - 1]} ${created.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('My Routine', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: _routine == null ? _buildEmptyState() : _buildRoutine(),
      ),
    );
  }

  // Shown when the user hasn't saved a routine from the chat yet
  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.spa_outlined, size: 48, color: Colors.black26),
        const SizedBox(height: 16),
        const Text(
          'No saved routine yet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Chat with Glow about your skin, then tap "Save this routine" under your recommendation.',
          style: TextStyle(color: Colors.black54, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _progressButton(),
      ],
    );
  }

  Widget _buildRoutine() {
    final morning = List<String>.from(_routine!['morning_steps'] ?? []);
    final evening = List<String>.from(_routine!['evening_steps'] ?? []);
    final note = (_routine!['note'] as String?)?.trim();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(_savedOnText(), style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 12),

        if (note != null && note.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDCE3D5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(note, style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
          const SizedBox(height: 16),
        ],

        _stepsCard(title: 'Morning Routine', icon: Icons.wb_sunny_outlined, steps: morning),
        const SizedBox(height: 16),
        _stepsCard(title: 'Evening Routine', icon: Icons.nightlight_outlined, steps: evening),
        const SizedBox(height: 16),

        const Text(
          'Guidance only. This is not medical advice. See a professional if your skin worsens.',
          style: TextStyle(fontSize: 11, color: Colors.black45),
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
              // Close this page, then switch to the Routine tab
              Navigator.pop(context);
              widget.onLogRoutine?.call();
            },
            child: const Text("Log today's routine"),
          ),
        ),
        const SizedBox(height: 10),
        _progressButton(),
      ],
    );
  }

  Widget _stepsCard({required String title, required IconData icon, required List<String> steps}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (steps.isEmpty)
            const Text('No steps', style: TextStyle(color: Colors.black45))
          else
            ...steps.asMap().entries.map(
                  (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCE3D5),
                        shape: BoxShape.circle,
                      ),
                      child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.value, style: const TextStyle(height: 1.3))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _progressButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4A5A3A),
          side: const BorderSide(color: Color(0xFF4A5A3A)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RoutineProgressPage()),
        ),
        icon: const Icon(Icons.local_fire_department_outlined, size: 18),
        label: const Text('View progress & streaks'),
      ),
    );
  }
}