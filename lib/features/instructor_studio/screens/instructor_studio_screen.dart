import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/assignment_model.dart';
import '../../../models/course_model.dart';
import '../../../models/dashboard_models.dart';
import '../../../models/enrollment_model.dart';
import '../../../models/instructor_model.dart';
import '../../home/screens/home_screen.dart';
import '../widgets/course_form_dialog.dart';
import '../widgets/instructor_analytic_tab.dart';
import '../widgets/instructor_manage_tab.dart';
import '../widgets/instructor_profile_tab.dart';

class InstructorStudioScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const InstructorStudioScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  ConsumerState<InstructorStudioScreen> createState() => _InstructorStudioScreenState();
}

class _InstructorStudioScreenState extends ConsumerState<InstructorStudioScreen> {
  late int _currentTabIndex;

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

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTab.clamp(0, 3);
    _loadAllData();
  }

  @override
  void didUpdateWidget(covariant InstructorStudioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      setState(() => _currentTabIndex = widget.initialTab.clamp(0, 3));
    }
  }

  Future<void> _loadAllData() async {
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

      final results = await Future.wait([
        dashRepo.getInstructorDashboard().catchError((_) => InstructorDashboardDTO()),
        dashRepo.getEnrollmentReports().catchError((_) => EnrollmentReportDTO()),
        dashRepo.getQuizReports().catchError((_) => QuizReportDTO()),
        courseRepo.getInstructorCoursesMe().catchError((_) => <CourseModel>[]),
        assignRepo.getAssignments().catchError((_) => <AssignmentModel>[]),
        enrollRepo.getAllEnrollments().catchError((_) => <EnrollmentModel>[]),
        instRepo.getMyProfile().catchError((_) => InstructorModel(id: 0, fullName: '')),
      ]);

      if (mounted) {
        setState(() {
          _dashboard = results[0] as InstructorDashboardDTO;
          _enrollmentReport = results[1] as EnrollmentReportDTO;
          _quizReport = results[2] as QuizReportDTO;
          _myCourses = results[3] as List<CourseModel>;
          _assignments = results[4] as List<AssignmentModel>;
          _enrolledStudents = results[5] as List<EnrollmentModel>;
          _instructorProfile = results[6] as InstructorModel;

          if (_assignments.isNotEmpty) {
            _selectedAssignmentIdForGrading ??= _assignments.first.assignmentId;
          }

          _isLoading = false;
        });

        if (_selectedAssignmentIdForGrading != null) {
          final subs = await assignRepo.getSubmissions(_selectedAssignmentIdForGrading!).catchError((_) => <AssignmentSubmissionModel>[]);
          if (mounted) {
            setState(() => _submissions = subs);
          }
        }
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

  void _openCourseCreateDialog() {
    CourseFormDialog.show(
      context,
      onSaved: _loadAllData,
    );
  }

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
              TextField(
                controller: scoreCtrl,
                decoration: const InputDecoration(labelText: 'Score (pts)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: gradeCtrl,
                decoration: const InputDecoration(labelText: 'Letter Grade (A-F)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: feedbackCtrl,
                decoration: const InputDecoration(labelText: 'Feedback'),
                maxLines: 3,
              ),
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
                _loadAllData();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: _currentTabIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentTabIndex != 0) {
          setState(() => _currentTabIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
        body: SafeArea(
          child: Column(
            children: [
              ApiAlert(error: _error, onRetry: _loadAllData),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : IndexedStack(
                        index: _currentTabIndex,
                        children: [
                          // Tab 0: Home (Student / unauthenticated Home page design listing courses)
                          const HomeScreen(),

                          // Tab 1: Analytic (Amount of students, pie chart per course, avg rating)
                          InstructorAnalyticTab(
                            dashboard: _dashboard,
                            enrollmentReport: _enrollmentReport,
                            quizReport: _quizReport,
                            courses: _myCourses,
                            onBackTap: () => setState(() => _currentTabIndex = 0),
                            onRefresh: _loadAllData,
                          ),

                          // Tab 2: Manage (Mockup Screen 3)
                          InstructorManageTab(
                            courses: _myCourses,
                            assignments: _assignments,
                            submissions: _submissions,
                            selectedAssignmentId: _selectedAssignmentIdForGrading,
                            onSelectAssignment: (id) async {
                              setState(() => _selectedAssignmentIdForGrading = id);
                              if (id != null) {
                                final subs = await ref.read(assignmentRepositoryProvider).getSubmissions(id);
                                setState(() => _submissions = subs);
                              }
                            },
                            onOpenGrading: _openGradingModal,
                            enrolledStudents: _enrolledStudents,
                            quizReport: _quizReport,
                            onOpenCourseCreate: _openCourseCreateDialog,
                            onCourseMutated: _loadAllData,
                            onBackTap: () => setState(() => _currentTabIndex = 0),
                            onRefresh: _loadAllData,
                          ),

                          // Tab 3: Profile (Instructor Profile)
                          InstructorProfileTab(
                            profile: _instructorProfile,
                            dashboard: _dashboard,
                            onProfileUpdated: _loadAllData,
                            onSignOut: () async {
                              await ref.read(authRepositoryProvider).logout();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        // Redesigned Bottom Navigation Bar with Home, Analytic, Manage, Profile
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFF1F3F6),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 0,
            currentIndex: _currentTabIndex,
            selectedItemColor: const Color(0xFF2F66F6),
            unselectedItemColor: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            onTap: (index) {
              setState(() => _currentTabIndex = index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 3.0),
                  child: Icon(Icons.home_outlined),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 3.0),
                  child: Icon(Icons.home_rounded),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 3.0),
                  child: Icon(Icons.bar_chart_outlined),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 3.0),
                  child: Icon(Icons.bar_chart_rounded),
                ),
                label: 'Analytic',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 3.0),
                  child: Icon(Icons.grid_view_outlined),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 3.0),
                  child: Icon(Icons.grid_view_rounded),
                ),
                label: 'Manage',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 3.0),
                  child: Icon(Icons.person_outline),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 3.0),
                  child: Icon(Icons.person_rounded),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
