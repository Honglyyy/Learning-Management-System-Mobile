import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/assignment_model.dart';
import '../../../models/course_model.dart';
import '../../../models/dashboard_models.dart';
import '../../../models/enrollment_model.dart';
import '../../../models/instructor_model.dart';
import '../widgets/course_form_dialog.dart';
import '../widgets/instructor_course_card.dart';

class InstructorStudioScreen extends ConsumerStatefulWidget {
  const InstructorStudioScreen({super.key});

  @override
  ConsumerState<InstructorStudioScreen> createState() => _InstructorStudioScreenState();
}

class _InstructorStudioScreenState extends ConsumerState<InstructorStudioScreen> {
  int _selectedSectionIndex = 0;

  final List<String> _sections = [
    'Overview',
    'Analytics & Reports',
    'My Courses',
    'Assignments & Grading',
    'Enrolled Students',
    'Profile & Bio',
    'Security',
  ];

  // Overview & Analytics Data
  InstructorDashboardDTO? _dashboard;
  EnrollmentReportDTO? _enrollmentReport;
  QuizReportDTO? _quizReport;

  // Courses
  List<CourseModel> _myCourses = [];

  // Assignments
  List<AssignmentModel> _assignments = [];
  List<AssignmentSubmissionModel> _submissions = [];
  int? _selectedAssignmentIdForGrading;

  // Students
  List<EnrollmentModel> _enrolledStudents = [];

  // Profile
  InstructorModel? _instructorProfile;

  // Security Form
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityFormKey = GlobalKey<FormState>();
  bool _isUpdatingPassword = false;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSectionData();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateToSection(int index) {
    setState(() => _selectedSectionIndex = index);
    _loadSectionData();
  }

  Future<void> _loadSectionData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashRepo = ref.read(dashboardRepositoryProvider);
      final courseRepo = ref.read(courseRepositoryProvider);
      final assignRepo = ref.read(assignmentRepositoryProvider);
      final enrollRepo = ref.read(enrollmentRepositoryProvider);
      final instRepo = ref.read(instructorRepositoryProvider);

      switch (_selectedSectionIndex) {
        case 0: // Overview
          _dashboard = await dashRepo.getInstructorDashboard();
          _enrollmentReport = await dashRepo.getEnrollmentReports().catchError((_) => EnrollmentReportDTO());
          break;
        case 1: // Analytics
          _enrollmentReport = await dashRepo.getEnrollmentReports();
          _quizReport = await dashRepo.getQuizReports().catchError((_) => QuizReportDTO());
          break;
        case 2: // Courses
          _myCourses = await courseRepo.getInstructorCoursesMe();
          break;
        case 3: // Assignments & Grading
          _assignments = await assignRepo.getAssignments();
          if (_assignments.isNotEmpty) {
            _selectedAssignmentIdForGrading ??= _assignments.first.assignmentId;
            _submissions = await assignRepo.getSubmissions(_selectedAssignmentIdForGrading!);
          }
          break;
        case 4: // Students
          _enrolledStudents = await enrollRepo.getAllEnrollments();
          break;
        case 5: // Profile
          _instructorProfile = await instRepo.getMyProfile();
          break;
        case 6: // Security
          break;
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // --- Section 0: Overview Dashboard ---
  Widget _buildOverviewSection(ThemeData theme) {
    if (_dashboard == null) return const Center(child: CircularProgressIndicator());
    final d = _dashboard!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Instructor Dashboard', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _buildKpiCard('Total Courses', '${d.totalCourses}', Icons.menu_book, Colors.blue),
                _buildKpiCard('Enrolled Students', '${d.totalStudents}', Icons.people, Colors.green),
                _buildKpiCard('Avg Rating', d.averageRating.toStringAsFixed(1), Icons.star, Colors.amber),
                _buildKpiCard('Gross Revenue', Formatters.formatCurrency(d.grossRevenue), Icons.attach_money, Colors.purple),
              ],
            );
          }),
          const SizedBox(height: 24),
          Text(
            'Studio Features',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _buildFeatureNavCard(
                  title: 'My Courses',
                  description: 'Manage & create curriculum',
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF3B82F6),
                  onTap: () => _navigateToSection(2),
                ),
                _buildFeatureNavCard(
                  title: 'Assignments',
                  description: 'Review submissions & grade',
                  icon: Icons.assignment_turned_in_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () => _navigateToSection(3),
                ),
                _buildFeatureNavCard(
                  title: 'Analytics & Reports',
                  description: 'Enrollment trends & insights',
                  icon: Icons.bar_chart_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _navigateToSection(1),
                ),
                _buildFeatureNavCard(
                  title: 'Enrolled Students',
                  description: 'Student roster & progress',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () => _navigateToSection(4),
                ),
                _buildFeatureNavCard(
                  title: 'Profile & Bio',
                  description: 'Edit instructor credentials',
                  icon: Icons.badge_rounded,
                  color: const Color(0xFF06B6D4),
                  onTap: () => _navigateToSection(5),
                ),
                _buildFeatureNavCard(
                  title: 'Security',
                  description: 'Password & account settings',
                  icon: Icons.security_rounded,
                  color: const Color(0xFFEC4899),
                  onTap: () => _navigateToSection(6),
                ),
              ],
            );
          }),
          const SizedBox(height: 24),
          if (_enrollmentReport != null && _enrollmentReport!.monthlyBreakdown.isNotEmpty) ...[
            Text('Enrollment Trends', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < _enrollmentReport!.monthlyBreakdown.length) {
                                return Text(_enrollmentReport!.monthlyBreakdown[idx].month, style: const TextStyle(fontSize: 10));
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _enrollmentReport!.monthlyBreakdown.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.enrollmentCount.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: theme.colorScheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Section 1: Analytics & Reports ---
  Widget _buildAnalyticsSection(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics & Student Reports', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_quizReport != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quiz Performance Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('Total Quizzes', '${_quizReport!.totalQuizzes}'),
                        _buildStatColumn('Overall Pass Rate', '${_quizReport!.overallPassRate.toStringAsFixed(0)}%'),
                        _buildStatColumn('Avg Quiz Score', '${_quizReport!.averageScore.toStringAsFixed(1)} pts'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_enrollmentReport != null && _enrollmentReport!.courseBreakdown.isNotEmpty) ...[
            const Text('Course Enrollment Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ..._enrollmentReport!.courseBreakdown.map((cb) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(cb.courseTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Total Enrolled: ${cb.totalEnrolled} • Active: ${cb.activeStudents}', style: const TextStyle(fontSize: 11)),
                    trailing: Text('${cb.completedStudents} Completed', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // --- Section 2: My Courses Management ---
  void _openCourseCreateDialog() {
    CourseFormDialog.show(
      context,
      onSaved: _loadSectionData,
    );
  }

  Widget _buildCoursesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Courses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Course'),
              onPressed: _openCourseCreateDialog,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _myCourses.isEmpty
              ? const EmptyState(
                  title: 'No courses published',
                  description: 'Create your first course to begin teaching.',
                )
              : ListView.builder(
                  itemCount: _myCourses.length,
                  itemBuilder: (context, index) {
                    final c = _myCourses[index];
                    return InstructorCourseCard(
                      key: ValueKey('course_${c.courseId}'),
                      course: c,
                      onCourseMutated: _loadSectionData,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- Section 3: Assignments & Grading ---
  void _openGradingModal(AssignmentSubmissionModel sub) {
    final scoreCtrl = TextEditingController(text: sub.score?.toString() ?? '100');
    final gradeCtrl = TextEditingController(text: sub.grade ?? 'A');
    final feedbackCtrl = TextEditingController(text: sub.feedback ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Grade: ${sub.studentName ?? "Student"}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sub.textSubmission != null && sub.textSubmission!.isNotEmpty) ...[
                const Text('Student Answer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(sub.textSubmission!, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
              ],
              TextField(controller: scoreCtrl, decoration: const InputDecoration(labelText: 'Score (pts)'), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: 'Letter Grade (A-F)')),
              const SizedBox(height: 10),
              TextField(controller: feedbackCtrl, decoration: const InputDecoration(labelText: 'Feedback'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(assignmentRepositoryProvider).gradeSubmission(
                      sub.submissionId,
                      score: num.tryParse(scoreCtrl.text) ?? 100,
                      grade: gradeCtrl.text.trim(),
                      feedback: feedbackCtrl.text.trim(),
                    );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                ToastService.showSuccess('Submission graded!');
                _loadSectionData();
              } catch (e) {
                ToastService.showError(e.toString());
              }
            },
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Assignments & Grading', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_assignments.isNotEmpty)
          DropdownButtonFormField<int>(
            initialValue: _selectedAssignmentIdForGrading,
            decoration: const InputDecoration(labelText: 'Select Assignment to Review Submissions'),
            items: _assignments.map((a) {
              return DropdownMenuItem(value: a.assignmentId, child: Text(a.title, overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: (id) async {
              setState(() => _selectedAssignmentIdForGrading = id);
              if (id != null) {
                final subs = await ref.read(assignmentRepositoryProvider).getSubmissions(id);
                setState(() => _submissions = subs);
              }
            },
          ),
        const SizedBox(height: 12),
        Expanded(
          child: _submissions.isEmpty
              ? const EmptyState(title: 'No student submissions', description: 'Student submissions will appear here for grading.')
              : ListView.builder(
                  itemCount: _submissions.length,
                  itemBuilder: (context, index) {
                    final s = _submissions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(s.studentName ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(
                          'Status: ${s.status} ${s.score != null ? "• Score: ${s.score} (${s.grade})" : ""}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          onPressed: () => _openGradingModal(s),
                          child: const Text('Grade', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- Section 4: Enrolled Students ---
  Widget _buildStudentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enrolled Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(
          child: _enrolledStudents.isEmpty
              ? const EmptyState(title: 'No enrolled students yet')
              : ListView.builder(
                  itemCount: _enrolledStudents.length,
                  itemBuilder: (context, index) {
                    final e = _enrolledStudents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(e.userName != null && e.userName!.isNotEmpty ? e.userName![0].toUpperCase() : 'S')),
                        title: Text(e.userName ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${e.courseTitle} • Progress: ${e.progressPercent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
                        trailing: Text(e.status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- Section 5: Profile & Bio ---
  Widget _buildProfileSection() {
    if (_instructorProfile == null) return const Center(child: CircularProgressIndicator());
    final p = _instructorProfile!;
    final nameCtrl = TextEditingController(text: p.fullName);
    final phoneCtrl = TextEditingController(text: p.phoneNumber ?? '');
    final bioCtrl = TextEditingController(text: p.biography ?? '');
    final expCtrl = TextEditingController(text: p.expertise ?? '');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Instructor Profile & Bio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
          const SizedBox(height: 12),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
          const SizedBox(height: 12),
          TextField(controller: bioCtrl, decoration: const InputDecoration(labelText: 'Biography'), maxLines: 4),
          const SizedBox(height: 12),
          TextField(controller: expCtrl, decoration: const InputDecoration(labelText: 'Expertise (comma separated, e.g. React, Flutter, Python)')),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(instructorRepositoryProvider).updateMyProfile({
                  'fullName': nameCtrl.text.trim(),
                  'phoneNumber': phoneCtrl.text.trim(),
                  'biography': bioCtrl.text.trim(),
                  'expertise': expCtrl.text.trim(),
                });
                ToastService.showSuccess('Profile updated successfully');
              } catch (e) {
                ToastService.showError(e.toString());
              }
            },
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildFeatureNavCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 12, color: theme.hintColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.hintColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Section 6: Security & Password ---
  Widget _buildSecuritySection(ThemeData theme) {
    return SingleChildScrollView(
      child: Form(
        key: _securityFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Security & Password', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Ensure your instructor account is secured with a strong password.', style: TextStyle(color: theme.hintColor, fontSize: 13)),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
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
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Update Password'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHome = _selectedSectionIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isHome ? 'Instructor Studio' : _sections[_selectedSectionIndex]),
        leading: isHome
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to Studio Home',
                onPressed: () => setState(() => _selectedSectionIndex = 0),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadSectionData,
          ),
        ],
      ),
      body: PopScope(
        canPop: isHome,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (!isHome) {
            setState(() => _selectedSectionIndex = 0);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ApiAlert(error: _error, onRetry: _loadSectionData),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : [
                        _buildOverviewSection(Theme.of(context)),
                        _buildAnalyticsSection(Theme.of(context)),
                        _buildCoursesSection(),
                        _buildAssignmentsSection(),
                        _buildStudentsSection(),
                        _buildProfileSection(),
                        _buildSecuritySection(Theme.of(context)),
                      ][_selectedSectionIndex],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
