import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/confidence_display_settings.dart';
import '../services/saved_routine_storage.dart';

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

  bool _consentGiven = false;

  bool get _welcomeComplete =>
      _isPregnant != null &&
          _hasHealthConcern != null &&
          _ageGroup != null &&
          _mainConcern != null;

  // Delete the scan photos from the phone when this page closes
  // (after Done, Skip or Back), so Glow doesn't keep them.
  @override
  void dispose() {
    for (final path in widget.imagePaths) {
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } catch (e) {
        debugPrint('Could not delete scan photo: $e');
      }
    }
    super.dispose();
  }

  bool get _knowYourSkinComplete =>
      _skinCondition != null && _rednessHistory != null && _consentGiven;

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

    // ---------- Escalated / follow-up: simple message, nothing to save ----------
    if (status == 'escalated' || status == 'follow_up_needed') {
      final isEscalated = status == 'escalated';
      final title = isEscalated ? 'Please see a professional' : 'We need a bit more info';
      final body = isEscalated
          ? '${result['message']}\n\nWe recommend consulting a healthcare professional for further guidance.'
          : (result['message'] ?? 'Please provide more detail.');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Center(child: Text(title)),
          content: SingleChildScrollView(child: Text(body)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // close dialog
                Navigator.pop(context); // leave the questions page
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
      return;
    }

    // ---------- Recommendation ----------
    final rec = result['recommendation'] as Map<String, dynamic>?;
    final morningSteps =
    ((rec?['morning_routine'] as List?) ?? []).map((e) => e.toString()).toList();
    final eveningSteps =
    ((rec?['evening_routine'] as List?) ?? []).map((e) => e.toString()).toList();
    final note = rec?['note'] as String?;
    final canSave = morningSteps.isNotEmpty || eveningSteps.isNotEmpty;

    bool isSaving = false;
    bool isSaved = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> save() async {
            setDialogState(() => isSaving = true);
            try {
              await SavedRoutineStorage.saveRoutine(
                morningSteps: morningSteps,
                eveningSteps: eveningSteps,
                note: note,
              );
              setDialogState(() => isSaved = true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Routine saved ✓')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not save routine: $e')),
                );
              }
            } finally {
              setDialogState(() => isSaving = false);
            }
          }

          return AlertDialog(
            title: const Center(child: Text('Your routine')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _routineSection('🌞 Morning', morningSteps),
                  const SizedBox(height: 14),
                  _routineSection('🌙 Evening', eveningSteps),
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(note, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                  const SizedBox(height: 14),
                  // Rebuilds if the user flips the numeric/verbal toggle
                  ValueListenableBuilder<bool>(
                    valueListenable: ConfidenceDisplaySettings.showNumeric,
                    builder: (_, showNumeric, __) => Text(
                      'Confidence: ${_confidenceText(result, showNumeric)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Skincare guidance only - not a diagnosis or treatment.',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ),
            actions: [
              if (canSave)
                TextButton.icon(
                  onPressed: (isSaving || isSaved) ? null : save,
                  icon: isSaving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(isSaved ? Icons.check : Icons.bookmark_add_outlined),
                  label: Text(isSaved ? 'Saved' : 'Save this routine'),
                ),
              TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                  Navigator.pop(dialogContext); // close dialog
                  Navigator.pop(context); // leave the questions page
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _confidenceText(Map<String, dynamic> result, bool showNumeric) {
    final confidenceValue = result['confidence'];
    final confidenceLabel = result['confidence_label'] as String?;
    if (showNumeric) {
      return confidenceValue is num ? '${(confidenceValue * 100).round()}%' : 'Unknown';
    }
    return confidenceLabel ?? 'Unknown';
  }

  Widget _routineSection(String heading, List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        if (steps.isEmpty)
          const Text('N/A')
        else
          ...steps.asMap().entries.map(
                (e) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('${e.key + 1}. ${e.value}'),
            ),
          ),
      ],
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

  Widget _buildConsentBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: Color(0xFF4A5A3A)),
              SizedBox(width: 6),
              Text('Your privacy', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Your photo is sent over a secure connection to Google\'s Gemini AI for analysis.\n'
                '• Glow does not save your photo. It is deleted from your phone once you leave this page.\n'
                '• Glow gives general skincare guidance only. It is not a medical diagnosis or treatment. '
                'Please see a healthcare professional for any medical concern.',
            style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => setState(() => _consentGiven = !_consentGiven),
            child: Row(
              children: [
                Checkbox(
                  value: _consentGiven,
                  activeColor: const Color(0xFF4A5A3A),
                  onChanged: (v) => setState(() => _consentGiven = v ?? false),
                ),
                const Expanded(
                  child: Text(
                    'I understand and agree',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        const SizedBox(height: 28),
        _buildConsentBox(),
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