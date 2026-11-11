import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/assignment_model.dart';
import '../../../models/course_model.dart';
import '../../../models/dashboard_models.dart';
import '../../../models/enrollment_model.dart';
import '../../../models/instructor_model.dart';
import '../../home/screens/home_screen.dart';
import '../widgets/assignment_form_dialog.dart';
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

  AssignmentModel _normalizeAssignment(AssignmentModel assignment, CourseModel course) {
    if (assignment.courseId != null && assignment.courseTitle != null) {
      return assignment;
    }
    return AssignmentModel(
      assignmentId: assignment.assignmentId,
      title: assignment.title,
      description: assignment.description,
      instructions: assignment.instructions,
      startDate: assignment.startDate,
      dueDate: assignment.dueDate,
      maxScore: assignment.maxScore,
      supportingFileUrl: assignment.supportingFileUrl,
      supportingFilePublicId: assignment.supportingFilePublicId,
      allowResubmission: assignment.allowResubmission,
      courseId: assignment.courseId ?? course.courseId,
      courseTitle: assignment.courseTitle ?? course.title,
      sectionId: assignment.sectionId,
      sectionTitle: assignment.sectionTitle,
      status: assignment.status,
    );
  }

  AssignmentSubmissionModel _normalizeSubmission(
    AssignmentSubmissionModel sub,
    AssignmentModel? assignment,
  ) {
    if (sub.assignmentId != null && sub.assignmentTitle != null) {
      return sub;
    }
    return AssignmentSubmissionModel(
      submissionId: sub.submissionId,
      assignmentId: sub.assignmentId ?? assignment?.assignmentId,
      assignmentTitle: sub.assignmentTitle ?? assignment?.title,
      studentId: sub.studentId,
      studentName: sub.studentName,
      studentEmail: sub.studentEmail,
      textSubmission: sub.textSubmission,
      fileUrl: sub.fileUrl,
      filePublicId: sub.filePublicId,
      submittedAt: sub.submittedAt,
      status: sub.status,
      score: sub.score,
      grade: sub.grade,
      feedback: sub.feedback,
      gradedAt: sub.gradedAt,
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _formatDateTime(dynamic value) {
    final dt = _parseDate(value);
    if (dt == null) return value?.toString() ?? '';
    return Formatters.formatDateTime(dt);
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
        enrollRepo.getAllEnrollments().catchError((_) => <EnrollmentModel>[]),
        instRepo.getMyProfile().catchError((_) => InstructorModel(id: 0, fullName: '')),
      ]);

      final myCourses = results[3] as List<CourseModel>;

      // Fetch assignments per instructor course (backend exposes /api/courses/{courseId}/assignments)
      final perCourseAssignments = myCourses.isEmpty
          ? <List<AssignmentModel>>[]
          : await Future.wait(
              myCourses.map(
                (c) => assignRepo
                    .getCourseAssignments(c.courseId)
                    .catchError((_) => <AssignmentModel>[]),
              ),
            );

      final seenAssignmentIds = <int>{};
      final loadedAssignments = <AssignmentModel>[];
      for (var i = 0; i < myCourses.length; i++) {
        final course = myCourses[i];
        for (final a in perCourseAssignments[i]) {
          if (seenAssignmentIds.add(a.assignmentId)) {
            loadedAssignments.add(_normalizeAssignment(a, course));
          }
        }
      }

      // Fetch submissions across all instructor assignments in parallel
      final perAssignmentSubmissions = loadedAssignments.isEmpty
          ? <List<AssignmentSubmissionModel>>[]
          : await Future.wait(
              loadedAssignments.map(
                (a) => assignRepo
                    .getSubmissions(a.assignmentId)
                    .catchError((_) => <AssignmentSubmissionModel>[]),
              ),
            );

      final seenSubmissionIds = <int>{};
      final loadedSubmissions = <AssignmentSubmissionModel>[];
      for (var i = 0; i < loadedAssignments.length; i++) {
        final assignment = loadedAssignments[i];
        for (final sub in perAssignmentSubmissions[i]) {
          if (sub.submissionId == 0 || seenSubmissionIds.add(sub.submissionId)) {
            loadedSubmissions.add(_normalizeSubmission(sub, assignment));
          }
        }
      }

      // Sort newest submissions first
      loadedSubmissions.sort((a, b) {
        final da = _parseDate(a.submittedAt);
        final db = _parseDate(b.submittedAt);
        if (da != null && db != null) return db.compareTo(da);
        if (db != null) return 1;
        if (da != null) return -1;
        return b.submissionId.compareTo(a.submissionId);
      });

      if (mounted) {
        setState(() {
          _dashboard = results[0] as InstructorDashboardDTO;
          _enrollmentReport = results[1] as EnrollmentReportDTO;
          _quizReport = results[2] as QuizReportDTO;
          _myCourses = myCourses;
          _assignments = loadedAssignments;
          _submissions = loadedSubmissions;
          _enrolledStudents = results[4] as List<EnrollmentModel>;
          _instructorProfile = results[5] as InstructorModel;

          if (_selectedAssignmentIdForGrading != null &&
              !_assignments.any((a) => a.assignmentId == _selectedAssignmentIdForGrading)) {
            _selectedAssignmentIdForGrading = null;
          }

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

  void _openCourseCreateDialog() {
    CourseFormDialog.show(
      context,
      onSaved: _loadAllData,
    );
  }

  void _openAssignmentCreateDialog([int? initialCourseId]) {
    if (_myCourses.isEmpty) {
      ToastService.showWarning('Create a course first before adding assignments');
      return;
    }
    AssignmentFormDialog.show(
      context,
      courses: _myCourses,
      initialCourseId: initialCourseId,
      onSaved: _loadAllData,
    );
  }

  void _openAssignmentEditDialog(AssignmentModel assignment) {
    AssignmentFormDialog.show(
      context,
      courses: _myCourses,
      assignment: assignment,
      onSaved: _loadAllData,
    );
  }

  Future<void> _deleteAssignment(AssignmentModel assignment) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Assignment',
      message:
          'Are you sure you want to delete "${assignment.title}"? All student submissions for this assignment will also be removed.',
      confirmLabel: 'Delete',
    );
    if (confirmed == true) {
      try {
        await ref.read(assignmentRepositoryProvider).deleteAssignment(assignment.assignmentId);
        ToastService.showSuccess('Assignment deleted');
        if (_selectedAssignmentIdForGrading == assignment.assignmentId && mounted) {
          setState(() => _selectedAssignmentIdForGrading = null);
        }
        await _loadAllData();
      } catch (e) {
        ToastService.showError(e.toString());
      }
    }
  }

  Future<void> _openExternalFile(String rawUrl) async {
    final resolved = mediaUrl(rawUrl);
    final uri = Uri.tryParse(resolved);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ToastService.showError('Could not open attached file');
    }
  }

  void _openGradingModal(AssignmentSubmissionModel sub) {
    final assignment = _assignments.cast<AssignmentModel?>().firstWhere(
          (a) => a?.assignmentId == sub.assignmentId,
          orElse: () => null,
        );
    final maxScore = assignment?.maxScore ?? 100;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _GradeSubmissionDialog(
        submission: sub,
        assignmentTitle: assignment?.title ?? sub.assignmentTitle ?? 'Assignment',
        maxScore: maxScore,
        formattedSubmittedAt:
            sub.submittedAt != null ? _formatDateTime(sub.submittedAt) : null,
        onOpenFile: _openExternalFile,
        onSubmitGrade: ({score, grade, feedback}) async {
          await ref.read(assignmentRepositoryProvider).gradeSubmission(
                sub.submissionId,
                score: score,
                grade: grade,
                feedback: feedback,
              );
        },
        onGraded: () {
          ToastService.showSuccess('Submission graded!');
          _loadAllData();
        },
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
                                try {
                                  final assignment = _assignments.cast<AssignmentModel?>().firstWhere(
                                        (a) => a?.assignmentId == id,
                                        orElse: () => null,
                                      );
                                  final subs = await ref
                                      .read(assignmentRepositoryProvider)
                                      .getSubmissions(id);
                                  if (!mounted) return;
                                  final normalized = subs
                                      .map((s) => _normalizeSubmission(s, assignment))
                                      .toList();
                                  setState(() {
                                    _submissions = [
                                      ..._submissions.where((s) => s.assignmentId != id),
                                      ...normalized,
                                    ];
                                  });
                                } catch (e) {
                                  if (mounted) {
                                    ToastService.showError('Failed to load submissions: $e');
                                  }
                                }
                              }
                            },
                            onOpenGrading: _openGradingModal,
                            onCreateAssignment: _openAssignmentCreateDialog,
                            onEditAssignment: _openAssignmentEditDialog,
                            onDeleteAssignment: _deleteAssignment,
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

class _GradeSubmissionDialog extends StatefulWidget {
  final AssignmentSubmissionModel submission;
  final String assignmentTitle;
  final int maxScore;
  final String? formattedSubmittedAt;
  final Future<void> Function(String url) onOpenFile;
  final Future<void> Function({
    num? score,
    String? grade,
    String? feedback,
  }) onSubmitGrade;
  final VoidCallback onGraded;

  const _GradeSubmissionDialog({
    required this.submission,
    required this.assignmentTitle,
    required this.maxScore,
    this.formattedSubmittedAt,
    required this.onOpenFile,
    required this.onSubmitGrade,
    required this.onGraded,
  });

  @override
  State<_GradeSubmissionDialog> createState() => _GradeSubmissionDialogState();
}

class _GradeSubmissionDialogState extends State<_GradeSubmissionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _scoreCtrl;
  late final TextEditingController _gradeCtrl;
  late final TextEditingController _feedbackCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final sub = widget.submission;
    final initialScoreText = sub.score != null
        ? (sub.score! == sub.score!.toInt()
            ? sub.score!.toInt().toString()
            : sub.score!.toString())
        : '';
    _scoreCtrl = TextEditingController(text: initialScoreText);
    _gradeCtrl = TextEditingController(text: sub.grade ?? '');
    _feedbackCtrl = TextEditingController(text: sub.feedback ?? '');
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _gradeCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final rawScore = _scoreCtrl.text.trim();
      final parsedScore = rawScore.isEmpty ? null : num.tryParse(rawScore);
      await widget.onSubmitGrade(
        score: parsedScore,
        grade: _gradeCtrl.text.trim(),
        feedback: _feedbackCtrl.text.trim(),
      );
      final onGraded = widget.onGraded;
      if (mounted) {
        Navigator.of(context).pop();
      }
      onGraded();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      ToastService.showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.submission;

    return AlertDialog(
      title: Text('Grade: ${sub.studentName ?? "Student"}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.assignmentTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (sub.studentEmail != null && sub.studentEmail!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub.studentEmail!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                if (widget.formattedSubmittedAt != null &&
                    widget.formattedSubmittedAt!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Submitted: ${widget.formattedSubmittedAt} (${sub.status})',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 12),
                if (sub.textSubmission != null && sub.textSubmission!.trim().isNotEmpty) ...[
                  const Text(
                    'Student Answer:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      sub.textSubmission!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (sub.fileUrl != null && sub.fileUrl!.trim().isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () => widget.onOpenFile(sub.fileUrl!),
                    icon: const Icon(Icons.attach_file, size: 16),
                    label: const Text('Open Submitted File'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _scoreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Score (0 – ${widget.maxScore} pts)',
                    hintText: 'e.g. 90 (or leave blank for feedback only)',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    final trimmed = val?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      if (_feedbackCtrl.text.trim().isEmpty) {
                        return 'Enter a score or provide feedback';
                      }
                      return null;
                    }
                    final parsed = num.tryParse(trimmed);
                    if (parsed == null || parsed < 0 || parsed > widget.maxScore) {
                      return 'Enter a score between 0 and ${widget.maxScore}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _gradeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Letter Grade (Optional)',
                    helperText: 'Leave blank to auto-calculate from score',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _feedbackCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Feedback',
                    hintText: 'Write constructive comments for the student...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Grade'),
        ),
      ],
    );
  }
}
