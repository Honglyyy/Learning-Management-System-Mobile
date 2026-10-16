import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../models/dashboard_models.dart';
import '../../../../models/instructor_model.dart';

class InstructorProfileTab extends StatefulWidget {
  final InstructorModel? profile;
  final InstructorDashboardDTO? dashboard;
  final VoidCallback onProfileUpdated;
  final VoidCallback onSignOut;

  const InstructorProfileTab({
    super.key,
    required this.profile,
    required this.dashboard,
    required this.onProfileUpdated,
    required this.onSignOut,
  });

  @override
  State<InstructorProfileTab> createState() => _InstructorProfileTabState();
}

class _InstructorProfileTabState extends State<InstructorProfileTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _expCtrl;

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityFormKey = GlobalKey<FormState>();

  bool _isSavingProfile = false;
  bool _isUpdatingPassword = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: widget.profile?.phoneNumber ?? '');
    _bioCtrl = TextEditingController(text: widget.profile?.biography ?? '');
    _expCtrl = TextEditingController(text: widget.profile?.expertise ?? '');
  }

  @override
  void didUpdateWidget(covariant InstructorProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile && widget.profile != null) {
      _nameCtrl.text = widget.profile!.fullName;
      _phoneCtrl.text = widget.profile!.phoneNumber ?? '';
      _bioCtrl.text = widget.profile!.biography ?? '';
      _expCtrl.text = widget.profile!.expertise ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _expCtrl.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = widget.profile;
    final avatarUrl = mediaUrl(p?.profilePhotoUrl);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFF1F3F6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFF3B67F6).withValues(alpha: 0.15),
                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          (p?.fullName.isNotEmpty == true) ? p!.fullName[0].toUpperCase() : 'I',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B67F6),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p?.fullName ?? 'Instructor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF11142D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B67F6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'INSTRUCTOR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3B67F6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p?.expertise ?? 'Course Creator & Educator',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : const Color(0xFF8F92A1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (p?.phoneNumber != null && p!.phoneNumber!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          p.phoneNumber!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Overview Stats Grid
          if (widget.dashboard != null) ...[
            LayoutBuilder(builder: (context, constraints) {
              final d = widget.dashboard!;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _buildStatTile('Total Courses', '${d.totalCourses}', Icons.menu_book, const Color(0xFF3B67F6), isDark),
                  _buildStatTile('Students', '${d.totalStudents}', Icons.people, const Color(0xFF10B981), isDark),
                  _buildStatTile('Avg Rating', d.averageRating.toStringAsFixed(1), Icons.star, const Color(0xFFF59E0B), isDark),
                  _buildStatTile('Revenue', Formatters.formatCurrency(d.grossRevenue), Icons.attach_money, const Color(0xFF8B5CF6), isDark),
                ],
              );
            }),
            const SizedBox(height: 24),
          ],

          // Profile Edit Form
          Text(
            'Edit Profile & Credentials',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF11142D),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFF1F3F6),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _expCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Expertise / Tags (e.g. Flutter, Dart, UI/UX)',
                    prefixIcon: Icon(Icons.workspace_premium_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Instructor Biography',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                Consumer(builder: (context, ref, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSavingProfile
                          ? null
                          : () async {
                              setState(() => _isSavingProfile = true);
                              try {
                                await ref.read(instructorRepositoryProvider).updateMyProfile({
                                  'fullName': _nameCtrl.text.trim(),
                                  'phoneNumber': _phoneCtrl.text.trim(),
                                  'biography': _bioCtrl.text.trim(),
                                  'expertise': _expCtrl.text.trim(),
                                });
                                ToastService.showSuccess('Profile updated successfully');
                                widget.onProfileUpdated();
                              } catch (e) {
                                ToastService.showError(e.toString());
                              } finally {
                                if (mounted) setState(() => _isSavingProfile = false);
                              }
                            },
                      child: _isSavingProfile
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Profile Changes'),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security & Password Form
          Text(
            'Security & Password',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF11142D),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFF1F3F6),
              ),
            ),
            child: Form(
              key: _securityFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_reset),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (val.length < 6) return 'Must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                    validator: (val) {
                      if (val != _newPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Consumer(builder: (context, ref, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUpdatingPassword
                            ? null
                            : () async {
                                if (!_securityFormKey.currentState!.validate()) return;
                                setState(() => _isUpdatingPassword = true);
                                try {
                                  await ref.read(userRepositoryProvider).changePassword(
                                        _oldPasswordController.text,
                                        _newPasswordController.text,
                                      );
                                  _oldPasswordController.clear();
                                  _newPasswordController.clear();
                                  _confirmPasswordController.clear();
                                  ToastService.showSuccess('Password updated successfully');
                                } catch (e) {
                                  ToastService.showError(e.toString());
                                } finally {
                                  if (mounted) setState(() => _isUpdatingPassword = false);
                                }
                              },
                        child: _isUpdatingPassword
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Update Password'),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Preferences & Sign Out
          Text(
            'App Preferences',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF11142D),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFF1F3F6),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Consumer(builder: (context, ref, _) {
                  return SwitchListTile(
                    title: const Text('Dark Theme'),
                    subtitle: const Text('Switch between Light and Dark interface'),
                    secondary: Icon(
                      isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      color: const Color(0xFF3B67F6),
                    ),
                    value: isDark,
                    onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                  );
                }),
                Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFF1F3F6)),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  onTap: widget.onSignOut,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFF1F3F6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF11142D),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
