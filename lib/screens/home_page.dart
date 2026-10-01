import 'package:flutter/material.dart';
import 'package:skincare_ai_system/main.dart';
import '../services/streak_service.dart';
import 'scan_screen.dart';
import 'scan_questions_page.dart';

class HomePage extends StatefulWidget {
  /// Switches the bottom nav to the Routine tab (same as tapping it)
  final VoidCallback? onGoToRoutine;

  const HomePage({super.key, this.onGoToRoutine});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // The streak itself is loaded by StreakService (shared with the nav badge)
  Future<void> _loadStreak() => StreakService.refresh();

  // ---------- Scan ----------

  Future<void> _startScan() async {
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

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadStreak,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting + notification bell
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kia ora,',
                        style: TextStyle(
                            fontSize: 35, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'How is your skin today?',
                        style: TextStyle(fontSize: 20, color: Colors.black54),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Icon(Icons.notifications_none, size: 22),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Skin check card
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start your skin check',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Get personalised skincare routine with Glow!',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.face_retouching_natural, size: 40),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A5A3A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _startScan,
                        child: const Text('Analyses Skin with AI'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Streak card
              _buildStreakCard(),

              const SizedBox(height: 28),

              // How it works
              const Text(
                'How it works',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              _buildStepRow(
                icon: Icons.camera_alt_outlined,
                title: 'Scan/upload',
                subtitle: 'Take a clear photo of your face',
              ),
              _buildStepRow(
                icon: Icons.help_outline,
                title: 'Answer Question',
                subtitle: "We'll ask a few questions about your skin",
              ),
              _buildStepRow(
                icon: Icons.check_circle_outline,
                title: 'Get Recommendation',
                subtitle: 'Receive a safe and personalised skincare routine',
              ),

              const SizedBox(height: 16),

              // Disclaimer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'This app for skincare guidance only - not for diagnosis or treatment.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    // Rebuild whenever StreakService updates
    return AnimatedBuilder(
      animation: Listenable.merge([
        StreakService.currentStreak,
        StreakService.loggedToday,
        StreakService.isLoading,
      ]),
      builder: (context, _) => _streakCardContent(
        streak: StreakService.currentStreak.value,
        loggedToday: StreakService.loggedToday.value,
        isLoading: StreakService.isLoading.value,
      ),
    );
  }

  Widget _streakCardContent({
    required int streak,
    required bool loggedToday,
    required bool isLoading,
  }) {
    final String title;
    if (isLoading) {
      title = 'Loading your streak...';
    } else if (streak == 0) {
      title = 'Start your streak today';
    } else {
      title = '$streak-day streak';
    }

    final String subtitle = loggedToday
        ? "Today's routine is logged. Nice work!"
        : 'Tap to log today\'s routine';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onGoToRoutine,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFDCE3D5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_fire_department,
                  color: Color(0xFF4A5A3A), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(
              loggedToday ? Icons.check_circle : Icons.chevron_right,
              color: loggedToday ? const Color(0xFF4A5A3A) : Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}