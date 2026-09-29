import 'package:flutter/material.dart';
import 'package:skincare_ai_system/main.dart';
import 'scan_screen.dart';
import 'scan_questions_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            // Aligns children to the left instead of centering them
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //notification bell icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // pushes items to opposite ends
                children: [
                  // Left side: greeting text stacked vertically
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kia ora,',
                        style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'How is your skin today?',
                        style: TextStyle(fontSize: 20, color: Colors.black54),
                      ),
                    ],
                  ),

                  // Right side: notification bell icon inside a circle border
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

              const SizedBox(height: 24), // empty vertical space (like margin)

              // button with icon and text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE3D5), // soft sage green background
                  borderRadius: BorderRadius.circular(20), // rounded corners
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Expanded = lets the text take up remaining space
                        // without overflowing next to the icon
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start your skin check',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Get personalised skincare routine with Glow!',
                                style: TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.face_retouching_natural, size: 40),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Full-width button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A5A3A), // dark green
                          foregroundColor: Colors.white, // text color
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final imagePaths = await Navigator.push<List<String>>(
                            context,
                            MaterialPageRoute(builder: (_) => SkinScanScreen(cameras: cameras)),
                          );

                          if (imagePaths == null || imagePaths.length != 3) return;

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ScanQuestionsPage(imagePaths: imagePaths)),
                            );
                          }
                        },
                        child: const Text('Analyses Skin with AI'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Instruction of the app and how it works
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

              // warning message about the app
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
      );

  }

  // helper method to create a row for each step
  Widget _buildStepRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // space below each row
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12), // space between icon and text
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