import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Your privacy matters to us. This app collects only the information '
                    'necessary to provide personalised, low-risk skincare guidance.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text('What we collect', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                '• Account information (email)\n'
                    '• Skin profile details you provide (skin type, concerns, allergies)\n'
                    '• Routine logs you choose to save\n'
                    '• Optional profile photo',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text('How we use it', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                'Your information is used solely to generate skincare recommendations '
                    'and track your routine progress. It is not sold or shared with third '
                    'parties for advertising purposes.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text('Important note', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                'This app provides low-risk skincare guidance only and is not a '
                    'diagnostic or medical tool. Always consult a healthcare professional '
                    'for medical concerns.',
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}