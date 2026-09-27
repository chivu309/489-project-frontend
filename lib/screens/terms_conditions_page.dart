import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Terms and Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('1. Purpose of this app', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                'This app provides general, low-risk skincare guidance based on '
                    'information you provide. It is not intended to diagnose, treat, '
                    'cure, or prevent any medical condition.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text('2. No medical advice', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                'Recommendations are generated using AI and general skincare '
                    'knowledge. They should not replace advice from a dermatologist '
                    'or other qualified healthcare provider.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text('3. Your responsibility', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                'You are responsible for reviewing any suggested products or '
                    'ingredients for personal allergies or sensitivities before use.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text('4. Academic project', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                'This application is developed as part of an academic research '
                    'project and is intended as a prototype, not a commercial product.',
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}