import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';
import 'routine_progress_page.dart';
import 'edit_skin_profile_page.dart';
import 'privacy_policy_page.dart';
import 'terms_conditions_page.dart';
import 'reminder_page.dart';
import '../services/skin_profile_storage.dart';
import 'my_routine_page.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onGoToRoutine;
  const ProfilePage({super.key, this.onGoToRoutine});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? get _currentUser => Supabase.instance.client.auth.currentUser;

  String? _avatarUrl;
  bool _isUploadingAvatar = false;

  // ---------- Skin profile state ----------
  String _skinType = 'Not set';
  String _skinConcern = 'Not set';
  String _allergies = 'None';
  String _lastAnalysisDate = '-';
  bool _isLoadingSkinProfile = true;

  @override
  void initState() {
    super.initState();
    _avatarUrl = _currentUser?.userMetadata?['avatar_url'] as String?;
    _loadSkinProfile();
  }

  Future<void> _loadSkinProfile() async {
    try {
      final profile = await SkinProfileStorage.loadProfile();
      if (profile != null && mounted) {
        setState(() {
          _skinType = profile['skin_type'] ?? 'Not set';
          _skinConcern = profile['skin_concern'] ?? 'Not set';
          _allergies = profile['allergies'] ?? 'None';
          _lastAnalysisDate = profile['last_analysis_date'] ?? '-';
        });
      }
    } catch (e) {
      debugPrint('Failed to load skin profile: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSkinProfile = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final userId = _currentUser!.id;
      final fileBytes = await pickedFile.readAsBytes();
      final filePath = '$userId/avatar.jpg';

      await Supabase.instance.client.storage.from('avatars').uploadBinary(
        filePath,
        fileBytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );

      final publicUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(filePath);
      final freshUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': freshUrl}),
      );

      if (mounted) {
        setState(() => _avatarUrl = freshUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await Supabase.instance.client.auth.signOut();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  void _handleMenuTap(String label) {
    switch (label) {
      case 'My Routine':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyRoutinePage(onLogRoutine: widget.onGoToRoutine),
          ),
        );
        break;
      case 'Log My Routine':
        widget.onGoToRoutine?.call();
        break;
      case 'Privacy Policy':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
        );
        break;
      case 'Reminder':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReminderPage()),
        );
        break;
      case 'Terms and Conditions':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
        );
        break;
      default:
        break;
    }
  }

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
            const SizedBox(height: 20),
            _buildSignOutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final displayName = _currentUser?.email ?? 'Guest';

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
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFDCE3D5),
              backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
              child: _avatarUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.black54)
                  : null,
            ),
            if (_isUploadingAvatar)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black38,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCE3D5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          displayName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

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
                onPressed: () async {
                  final saved = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditSkinProfilePage(
                        initialSkinType: _skinType == 'Not set' ? 'Sensitive' : _skinType,
                        initialSkinConcern: _skinConcern == 'Not set' ? 'Acne' : _skinConcern,
                        initialAllergies: _allergies,
                      ),
                    ),
                  );
                  if (saved == true) {
                    _loadSkinProfile();
                  }
                },
                child: const Text('Edit'),
              ),
            ],
          ),
          const Divider(height: 20),
          _isLoadingSkinProfile
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
              : Column(
            children: [
              _buildInfoRow('Skin Type', _skinType),
              const Divider(height: 20),
              _buildInfoRow('Skin concern', _skinConcern),
              const Divider(height: 20),
              _buildInfoRow('Allergies', _allergies),
              const Divider(height: 20),
              _buildInfoRow('Last skin analyses', _lastAnalysisDate,
                  icon: Icons.calendar_today_outlined),
            ],
          ),
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
      onTap: () => _handleMenuTap(label),
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

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4A5A3A),
          side: const BorderSide(color: Color(0xFF4A5A3A)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _signOut,
        child: const Text('Log out'),
      ),
    );
  }
}