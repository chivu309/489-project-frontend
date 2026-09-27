import 'package:flutter/material.dart';
import '../services/skin_profile_storage.dart';

class EditSkinProfilePage extends StatefulWidget {
  final String initialSkinType;
  final String initialSkinConcern;
  final String initialAllergies;

  const EditSkinProfilePage({
    super.key,
    required this.initialSkinType,
    required this.initialSkinConcern,
    required this.initialAllergies,
  });

  @override
  State<EditSkinProfilePage> createState() => _EditSkinProfilePageState();
}

class _EditSkinProfilePageState extends State<EditSkinProfilePage> {
  late String _skinType;
  late String _skinConcern;
  final _allergiesController = TextEditingController();

  bool _isSaving = false;

  final _skinTypeOptions = ['Sensitive', 'Oily', 'Dry', 'Combination', 'Normal'];
  final _concernOptions = ['Acne', 'Dryness', 'Redness', 'Irritation'];

  @override
  void initState() {
    super.initState();
    _skinType = widget.initialSkinType;
    _skinConcern = widget.initialSkinConcern;
    _allergiesController.text = widget.initialAllergies == 'None' ? '' : widget.initialAllergies;
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      await SkinProfileStorage.saveProfile(
        skinType: _skinType,
        skinConcern: _skinConcern,
        allergies: _allergiesController.text.trim().isEmpty
            ? 'None'
            : _allergiesController.text.trim(),
      );

      if (mounted) {
        // Return true so the Profile page knows to refresh
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Edit Skin Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Skin Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _skinTypeOptions.map((option) {
                  final isSelected = _skinType == option;
                  return _optionChip(
                    label: option,
                    isSelected: isSelected,
                    onTap: () => setState(() => _skinType = option),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              const Text('Skin Concern', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _concernOptions.map((option) {
                  final isSelected = _skinConcern == option;
                  return _optionChip(
                    label: option,
                    isSelected: isSelected,
                    onTap: () => setState(() => _skinConcern = option),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              const Text('Allergies', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  hintText: 'e.g. Fragrance, Retinol (leave blank for None)',
                  filled: true,
                  fillColor: const Color(0xFFF0F2ED),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A5A3A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBCC2B6) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A5A3A) : Colors.black26,
          ),
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