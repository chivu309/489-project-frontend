import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/confidence_display_settings.dart';

class ScanQuestionsPage extends StatefulWidget {
  final List<String> imagePaths; // three photos from SkinScanScreen

  const ScanQuestionsPage({super.key, required this.imagePaths});

  @override
  State<ScanQuestionsPage> createState() => _ScanQuestionsPageState();
}

class _ScanQuestionsPageState extends State<ScanQuestionsPage> {
  int _step = 0; // 0 = Welcome, 1 = Know your skin
  bool _isSubmitting = false;

  bool? _isPregnant;
  bool? _hasHealthConcern;
  String? _ageGroup;
  String? _mainConcern;
  String? _skinCondition;
  String? _rednessHistory;

  bool get _welcomeComplete =>
      _isPregnant != null && _hasHealthConcern != null && _ageGroup != null && _mainConcern != null;

  bool get _knowYourSkinComplete => _skinCondition != null && _rednessHistory != null;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final result = await ApiService.assessScan(
        imagePath: widget.imagePaths.first,
        isPregnant: _isPregnant!,
        hasHealthConcern: _hasHealthConcern!,
        ageGroup: _ageGroup!,
        mainConcern: _mainConcern!,
        skinCondition: _skinCondition!,
        rednessHistory: _rednessHistory!,
      );

      if (mounted) _showResult(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get a recommendation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showResult(Map<String, dynamic> result) {
    final status = result['status'];

    String title;
    String body;

    if (status == 'escalated') {
      title = 'Please see a professional';
      body = '${result['message']}\n\nWe recommend consulting a healthcare professional for further guidance.';
    } else if (status == 'follow_up_needed') {
      title = 'We need a bit more info';
      body = result['message'] ?? 'Please provide more detail.';
    } else {
      final rec = result['recommendation'] as Map<String, dynamic>?;
      final morning = ((rec?['morning_routine'] as List?) ?? []).join(', ');
      final evening = ((rec?['evening_routine'] as List?) ?? []).join(', ');
      final confidenceValue = result['confidence'];
      final confidenceLabel = result['confidence_label'] as String?;
      final confidenceText = ConfidenceDisplaySettings.showNumeric.value
          ? (confidenceValue != null ? '${((confidenceValue as num) * 100).round()}%' : 'Unknown')
          : (confidenceLabel ?? 'Unknown');

      title = 'Your routine';
      body = '🌞 Morning: ${morning.isEmpty ? 'N/A' : morning}\n\n'
          '🌙 Evening: ${evening.isEmpty ? 'N/A' : evening}\n\n'
          'Confidence: $confidenceText';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to Home
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (_step == 1) {
                        setState(() => _step = 0);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _step == 0 ? 0.5 : 1.0,
                      backgroundColor: Colors.black12,
                      color: const Color(0xFF4A5A3A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _step == 0 ? 'Welcome' : 'Know your skin',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: _step == 0 ? _buildWelcomeStep() : _buildKnowYourSkinStep(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Skip'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A5A3A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : _step == 0
                        ? (_welcomeComplete ? () => setState(() => _step = 1) : null)
                        : (_knowYourSkinComplete ? _submit : null),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : Text(_step == 0 ? 'continue' : 'continue'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Are you pregnant?', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _yesNoRow(_isPregnant, (v) => setState(() => _isPregnant = v)),
        const SizedBox(height: 20),

        const Text('Do you have any health concern?', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _yesNoRow(_hasHealthConcern, (v) => setState(() => _hasHealthConcern = v)),
        const SizedBox(height: 20),

        const Text('What is your age group?', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _choiceWrap(['20-30', '31-40', '41-50', '51-60'], _ageGroup, (v) => setState(() => _ageGroup = v)),
        const SizedBox(height: 20),

        const Text('Main concern about your skin', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _choiceWrap(['Acne', 'Redness', 'Dryness', 'Irritation'], _mainConcern, (v) => setState(() => _mainConcern = v)),
      ],
    );
  }

  Widget _buildKnowYourSkinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What is your skin condition?', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _choiceColumn(
          ['Very dry skin', 'Oily skin', 'Sensitive skin', 'Combination skin'],
          _skinCondition,
              (v) => setState(() => _skinCondition = v),
        ),
        const SizedBox(height: 24),

        const Text(
          'Have you ever experienced redness, itching, or burning sensations on your skin after using a new skincare product?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _choiceColumn(
          ['Never', 'Sometimes', 'Always'],
          _rednessHistory,
              (v) => setState(() => _rednessHistory = v),
        ),
      ],
    );
  }

  Widget _yesNoRow(bool? selected, ValueChanged<bool> onSelected) {
    return Row(
      children: [
        _pill('Yes', selected == true, () => onSelected(true)),
        const SizedBox(width: 12),
        _pill('No', selected == false, () => onSelected(false)),
      ],
    );
  }

  Widget _choiceWrap(List<String> options, String? selected, ValueChanged<String> onSelected) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((o) => _pill(o, selected == o, () => onSelected(o))).toList(),
    );
  }

  Widget _choiceColumn(List<String> options, String? selected, ValueChanged<String> onSelected) {
    return Column(
      children: options
          .map((o) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(width: double.infinity, child: _pill(o, selected == o, () => onSelected(o))),
      ))
          .toList(),
    );
  }

  Widget _pill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBCC2B6) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? const Color(0xFF4A5A3A) : Colors.black26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF2E3524) : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}