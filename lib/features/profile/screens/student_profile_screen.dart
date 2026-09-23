import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/activity_model.dart';
import '../../../models/student_model.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  ConsumerState<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _gender = 'NOT_SPECIFIC';
  DateTime? _dateOfBirth;
  String _educationLevel = 'Self-Taught/Other';

  StudentProfile? _profile;
  List<ActivityLog> _activities = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final studentRepo = ref.read(studentRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      final profile = await studentRepo.getProfile();
      final activities = await userRepo.getActivities().catchError((_) => <ActivityLog>[]);

      if (mounted) {
        setState(() {
          _profile = profile;
          _activities = activities;
          _fullNameController.text = profile.fullName ?? '';
          _phoneController.text = profile.phoneNumber ?? '';
          _gender = profile.gender ?? 'NOT_SPECIFIC';
          if (profile.dateOfBirth != null) {
            _dateOfBirth = DateTime.tryParse(profile.dateOfBirth!);
          }
          _educationLevel = profile.educationLevel ?? 'Self-Taught/Other';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await ref.read(studentRepositoryProvider).uploadPhotoBytes(bytes, picked.name);
      } else {
        final file = File(picked.path);
        await ref.read(studentRepositoryProvider).uploadPhoto(file);
      }
      ToastService.showSuccess('Profile photo updated');
      _loadProfile();
    } catch (e) {
      ToastService.showError('Photo upload failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final studentRepo = ref.read(studentRepositoryProvider);
      await studentRepo.updateProfile({
        'fullName': _fullNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'gender': _gender,
        'dateOfBirth': _dateOfBirth != null ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!) : null,
        'educationLevel': _educationLevel,
      });

      ToastService.showSuccess('Profile updated successfully');
      _loadProfile();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Old Password'),
                  validator: (val) => Validators.required(val, 'Old password required'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password (min 8)'),
                  validator: (val) => Validators.password(val, minLength: 8),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  validator: (val) => Validators.confirmPassword(val, newPasswordController.text),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSubmitting = true);
                      try {
                        await ref.read(userRepositoryProvider).changePassword(
                              oldPasswordController.text,
                              newPasswordController.text,
                            );
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                        ToastService.showSuccess('Password updated successfully');
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        ToastService.showError(e.toString());
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of your account?',
      confirmLabel: 'Sign Out',
      isDestructive: false,
    );

    if (confirmed == true) {
      await ref.read(authRepositoryProvider).logout();
      if (!mounted) return;
      ToastService.showInfo('Signed out');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final p = _profile;
    final photo = mediaUrl(p?.profilePhotoUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header card with photo & badges
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: theme.colorScheme.primary,
                          backgroundImage: photo.isNotEmpty ? (kIsWeb ? NetworkImage(photo) as ImageProvider : CachedNetworkImageProvider(photo)) : null,
                          onBackgroundImageError: photo.isNotEmpty ? (exception, stackTrace) {} : null,
                          child: photo.isEmpty
                              ? const Icon(Icons.person, size: 48, color: Colors.white)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: _isUploadingPhoto
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p?.fullName ?? 'Student',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        if (p?.studentCode != null)
                          Chip(
                            avatar: const Icon(Icons.badge, size: 16),
                            label: Text(p!.studentCode!, style: const TextStyle(fontSize: 12)),
                          ),
                        Chip(
                          avatar: const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                          label: Text('${p?.totalPoints ?? 0} Points', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            ApiAlert(error: _error),

            // Profile Edit Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline)),
                        validator: (val) => Validators.required(val, 'Full Name is required'),
                      ),
                      const SizedBox(height: 14),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        child: Text(
                          ref.watch(authRepositoryProvider).getUserEmail() ?? 'No email associated',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.transgender)),
                        items: const [
                          DropdownMenuItem(value: 'NOT_SPECIFIC', child: Text('Not Specific')),
                          DropdownMenuItem(value: 'MALE', child: Text('Male')),
                          DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                          DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                        ],
                        onChanged: (val) => setState(() => _gender = val ?? 'NOT_SPECIFIC'),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
                            firstDate: DateTime(1940),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _dateOfBirth = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          child: Text(
                            _dateOfBirth != null
                                ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
                                : 'Select date of birth',
                            style: TextStyle(
                              color: _dateOfBirth != null ? null : theme.hintColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _educationLevel,
                        decoration: const InputDecoration(labelText: 'Education Level', prefixIcon: Icon(Icons.school_outlined)),
                        items: const [
                          DropdownMenuItem(value: 'High School', child: Text('High School')),
                          DropdownMenuItem(value: 'Associate Degree', child: Text('Associate Degree')),
                          DropdownMenuItem(value: "Bachelor's Degree", child: Text("Bachelor's Degree")),
                          DropdownMenuItem(value: "Master's Degree", child: Text("Master's Degree")),
                          DropdownMenuItem(value: 'Doctorate/PhD', child: Text('Doctorate/PhD')),
                          DropdownMenuItem(value: 'Self-Taught/Other', child: Text('Self-Taught/Other')),
                        ],
                        onChanged: (val) => setState(() => _educationLevel = val ?? 'Self-Taught/Other'),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSaveProfile,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: _isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Save Profile Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Account Security Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Update your account security credentials', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showChangePasswordDialog,
              ),
            ),
            const SizedBox(height: 16),

            // Learning Reports & Analytics Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Learning Performance & Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.download, size: 20),
                          tooltip: 'Export Report',
                          onPressed: () {
                            ToastService.showSuccess('Downloading Learning Report PDF...');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text('${p?.totalPoints ?? 0}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                const SizedBox(height: 4),
                                const Text('Total Points', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text('${_activities.where((a) => '${a.activityType} ${a.description}'.toUpperCase().contains('QUIZ')).length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                                const SizedBox(height: 4),
                                const Text('Quizzes Attempted', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text('${_activities.where((a) => '${a.activityType} ${a.description}'.toUpperCase().contains('ASSIGNMENT')).length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                                const SizedBox(height: 4),
                                const Text('Assignments', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Activity Feed Card
            if (_activities.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Activity Log / Learning History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Chip(
                            label: Text('${_activities.length} Total', style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _activities.length.clamp(0, 10),
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final a = _activities[index];
                          final typeUpper = '${a.activityType} ${a.description}'.toUpperCase();
                          IconData actIcon = Icons.timeline;
                          Color actColor = theme.colorScheme.primary;

                          if (typeUpper.contains('ENROLL')) {
                            actIcon = Icons.school;
                            actColor = Colors.blue;
                          } else if (typeUpper.contains('LESSON')) {
                            actIcon = Icons.play_circle_outline;
                            actColor = Colors.purple;
                          } else if (typeUpper.contains('QUIZ')) {
                            actIcon = Icons.quiz;
                            actColor = Colors.green;
                          } else if (typeUpper.contains('ASSIGNMENT')) {
                            actIcon = Icons.assignment;
                            actColor = Colors.orange;
                          }

                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: actColor.withValues(alpha: 0.15),
                              child: Icon(actIcon, size: 16, color: actColor),
                            ),
                            title: Text(a.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            subtitle: a.timestamp != null ? Text(Formatters.timeAgo(a.timestamp), style: TextStyle(fontSize: 11, color: theme.hintColor)) : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
