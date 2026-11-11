import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../models/assignment_model.dart';
import '../../../../models/course_model.dart';
import '../../../../models/dashboard_models.dart';
import '../../../../models/enrollment_model.dart';
import 'instructor_course_card.dart';

enum ManageStudioTab { curriculum, assignments, students, quizzes }

class InstructorManageTab extends StatefulWidget {
  final List<CourseModel> courses;
  final List<AssignmentModel> assignments;
  final List<AssignmentSubmissionModel> submissions;
  final int? selectedAssignmentId;
  final Function(int?) onSelectAssignment;
  final Function(AssignmentSubmissionModel) onOpenGrading;
  final void Function(int? courseId)? onCreateAssignment;
  final void Function(AssignmentModel assignment)? onEditAssignment;
  final void Function(AssignmentModel assignment)? onDeleteAssignment;
  final List<EnrollmentModel> enrolledStudents;
  final QuizReportDTO? quizReport;
  final VoidCallback onOpenCourseCreate;
  final VoidCallback onCourseMutated;
  final VoidCallback onBackTap;
  final VoidCallback onRefresh;
  final ManageStudioTab initialActiveTab;

  const InstructorManageTab({
    super.key,
    required this.courses,
    required this.assignments,
    required this.submissions,
    required this.selectedAssignmentId,
    required this.onSelectAssignment,
    required this.onOpenGrading,
    this.onCreateAssignment,
    this.onEditAssignment,
    this.onDeleteAssignment,
    required this.enrolledStudents,
    required this.quizReport,
    required this.onOpenCourseCreate,
    required this.onCourseMutated,
    required this.onBackTap,
    required this.onRefresh,
    this.initialActiveTab = ManageStudioTab.curriculum,
  });

  @override
  State<InstructorManageTab> createState() => _InstructorManageTabState();
}

class _InstructorManageTabState extends State<InstructorManageTab> {
  late ManageStudioTab _activeTab;
  int? _selectedClassId;
  int? _selectedAssignmentCourseId;
  String _submissionStatusFilter = 'ALL';
  String _studentSearchQuery = '';
  final TextEditingController _studentSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialActiveTab;
  }

  @override
  void didUpdateWidget(covariant InstructorManageTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialActiveTab != oldWidget.initialActiveTab) {
      _activeTab = widget.initialActiveTab;
    }
  }

  @override
  void dispose() {
    _studentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate rates for the 3 circular ring indicators
    final publishedCount = widget.courses.where((c) => c.status == 'PUBLISHED').length;
    final publishedPercent = widget.courses.isNotEmpty ? (publishedCount / widget.courses.length) : 0.0;

    final gradedCount = widget.submissions.where((s) => s.isGraded).length;
    final gradedPercent = widget.submissions.isNotEmpty ? (gradedCount / widget.submissions.length) : 0.0;

    final quizPassPercent = (widget.quizReport != null && widget.quizReport!.overallPassRate > 0)
        ? (widget.quizReport!.overallPassRate / 100).clamp(0.0, 1.0)
        : 0.85;

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar: Back Button, Title 'Manage Studio', New Course Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: widget.onBackTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: isDark ? Colors.white : const Color(0xFF11142D),
                    ),
                  ),
                ),
                Text(
                  'Manage Studio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF11142D),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: widget.onOpenCourseCreate,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Course', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F66F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Studio Category Hubs (Courses, Curriculum, Grading, Students)
            _buildManagementHubs(isDark),
            const SizedBox(height: 22),

            // Analytics Progress Rings
            Text(
              'Studio Health & Progress',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF11142D),
              ),
            ),
            const SizedBox(height: 12),
            _buildAnalyticsRingsRow(
              isDark,
              publishedPercent: publishedPercent,
              gradedPercent: gradedPercent,
              quizPassPercent: quizPassPercent,
            ),
            const SizedBox(height: 24),

            // Active Tab Content Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _getTabTitle(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF11142D),
                    ),
                  ),
                ),
                if (_activeTab == ManageStudioTab.curriculum)
                  Text(
                    '${widget.courses.length} courses',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  )
                else if (_activeTab == ManageStudioTab.assignments &&
                    widget.courses.isNotEmpty &&
                    widget.onCreateAssignment != null)
                  ElevatedButton.icon(
                    onPressed: () => widget.onCreateAssignment?.call(_selectedAssignmentCourseId),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'New Assignment',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F66F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Active Tab View
            _buildActiveTabContent(isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getTabTitle() {
    switch (_activeTab) {
      case ManageStudioTab.curriculum:
        return 'Courses & Materials Editor';
      case ManageStudioTab.assignments:
        return 'Student Assignments & Grading';
      case ManageStudioTab.students:
        return 'Enrolled Students Roster';
      case ManageStudioTab.quizzes:
        return 'Quizzes & Assessments';
    }
  }

  // --- 4 Management Hub Cards ---
  Widget _buildManagementHubs(bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - 12) / 2;
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHubItem(
                width: itemWidth,
                isDark: isDark,
                isSelected: _activeTab == ManageStudioTab.curriculum,
                bgColor: const Color(0xFFEBF5FF),
                iconColor: const Color(0xFF2563EB),
                icon: Icons.video_library_rounded,
                title: 'Courses & Materials',
                subtitle: 'Lessons, videos, sections',
                onTap: () => setState(() => _activeTab = ManageStudioTab.curriculum),
              ),
              _buildHubItem(
                width: itemWidth,
                isDark: isDark,
                isSelected: _activeTab == ManageStudioTab.assignments,
                bgColor: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                icon: Icons.assignment_turned_in_rounded,
                title: 'Grading & Submissions',
                subtitle: 'Review & grade students',
                onTap: () => setState(() => _activeTab = ManageStudioTab.assignments),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHubItem(
                width: itemWidth,
                isDark: isDark,
                isSelected: _activeTab == ManageStudioTab.students,
                bgColor: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                icon: Icons.people_alt_rounded,
                title: 'Enrolled Students',
                subtitle: 'Progress & certificates',
                onTap: () => setState(() => _activeTab = ManageStudioTab.students),
              ),
              _buildHubItem(
                width: itemWidth,
                isDark: isDark,
                isSelected: _activeTab == ManageStudioTab.quizzes,
                bgColor: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF059669),
                icon: Icons.quiz_rounded,
                title: 'Quizzes & Tests',
                subtitle: 'Questions & pass rate',
                onTap: () => setState(() => _activeTab = ManageStudioTab.quizzes),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildHubItem({
    required double width,
    required bool isDark,
    required bool isSelected,
    required Color bgColor,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2F66F6).withValues(alpha: 0.25) : const Color(0xFFEFF4FF))
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2F66F6)
                : (isDark ? Colors.white12 : const Color(0xFFF1F3F6)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? bgColor.withValues(alpha: 0.2) : bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF2F66F6)
                    : (isDark ? Colors.white : const Color(0xFF11142D)),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : const Color(0xFF8F92A1)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- Analytics Rings Row ---
  Widget _buildAnalyticsRingsRow(
    bool isDark, {
    required double publishedPercent,
    required double gradedPercent,
    required double quizPassPercent,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildRingCard(
          isDark: isDark,
          label: 'Published',
          subtext: '${(publishedPercent * 100).toStringAsFixed(0)}%',
          percent: publishedPercent,
          activeColor: const Color(0xFF10B981),
          trackColor: const Color(0xFFD1FAE5),
        ),
        _buildRingCard(
          isDark: isDark,
          label: 'Graded',
          subtext: '${(gradedPercent * 100).toStringAsFixed(0)}%',
          percent: gradedPercent,
          activeColor: const Color(0xFFF59E0B),
          trackColor: const Color(0xFFFEF3C7),
        ),
        _buildRingCard(
          isDark: isDark,
          label: 'Quiz Pass',
          subtext: '${(quizPassPercent * 100).toStringAsFixed(0)}%',
          percent: quizPassPercent,
          activeColor: const Color(0xFF3B67F6),
          trackColor: const Color(0xFFDBEAFE),
        ),
      ],
    );
  }

  Widget _buildRingCard({
    required bool isDark,
    required String label,
    required String subtext,
    required double percent,
    required Color activeColor,
    required Color trackColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFF1F3F6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 5,
                    backgroundColor: isDark ? trackColor.withValues(alpha: 0.15) : trackColor,
                    valueColor: AlwaysStoppedAnimation(activeColor),
                    strokeCap: StrokeCap.round,
                  ),
                  Text(
                    subtext,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : const Color(0xFF8F92A1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Active Tab Content ---
  Widget _buildActiveTabContent(bool isDark) {
    switch (_activeTab) {
      case ManageStudioTab.curriculum:
        return _buildCurriculumSection(isDark);
      case ManageStudioTab.assignments:
        return _buildAssignmentsSection(isDark);
      case ManageStudioTab.students:
        return _buildStudentsSection(isDark);
      case ManageStudioTab.quizzes:
        return _buildQuizzesSection(isDark);
    }
  }

  // 1. Courses & Curriculum Section (using InstructorCourseCard with Section, Lesson, Video, and Quiz editing)
  Widget _buildCurriculumSection(bool isDark) {
    if (widget.courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: EmptyState(
          title: 'No courses published',
          description: 'Create your first course to begin adding sections, lessons, and video materials.',
        ),
      );
    }

    return Column(
      children: [
        // Instruction card
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B67F6).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3B67F6).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF3B67F6), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tap "Materials & Lessons" below any course to add sections, upload videos, attach documents, or configure quizzes.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.blue[200] : const Color(0xFF1E3A8A),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        // List of InstructorCourseCards with full material management
        ...widget.courses.map((c) {
          return InstructorCourseCard(
            key: ValueKey('manage_course_${c.courseId}'),
            course: c,
            onCourseMutated: widget.onCourseMutated,
          );
        }),
      ],
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _formatDateTime(dynamic value) {
    final dt = _parseDateTime(value);
    if (dt == null) return value?.toString() ?? '';
    return Formatters.formatDateTime(dt);
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

  String _formatScore(num value) {
    return value == value.toInt() ? value.toInt().toString() : value.toString();
  }

  // 2. Assignments & Grading Section
  Widget _buildAssignmentsSection(bool isDark) {
    if (widget.assignments.isEmpty && widget.submissions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFF1F3F6)),
        ),
        child: Column(
          children: [
            const EmptyState(
              title: 'No assignments yet',
              description:
                  'Create assignments inside your courses so students can submit work and receive grades.',
            ),
            if (widget.courses.isNotEmpty && widget.onCreateAssignment != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => widget.onCreateAssignment?.call(null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Assignment'),
              ),
            ],
          ],
        ),
      );
    }

    // Map courses and assignments for clean lookup & filtering
    final Map<int, String> courseMap = {};
    for (final c in widget.courses) {
      courseMap[c.courseId] = c.title;
    }
    for (final a in widget.assignments) {
      if (a.courseId != null && !courseMap.containsKey(a.courseId)) {
        courseMap[a.courseId!] =
            (a.courseTitle != null && a.courseTitle!.isNotEmpty)
                ? a.courseTitle!
                : 'Course #${a.courseId}';
      }
    }

    final Map<int, AssignmentModel> assignmentMap = {
      for (final a in widget.assignments) a.assignmentId: a,
    };

    final validCourseId = courseMap.containsKey(_selectedAssignmentCourseId)
        ? _selectedAssignmentCourseId
        : null;

    final filteredAssignments = validCourseId != null
        ? widget.assignments.where((a) => a.courseId == validCourseId).toList()
        : widget.assignments;

    final validAssignmentId = (widget.selectedAssignmentId != null &&
            filteredAssignments.any((a) => a.assignmentId == widget.selectedAssignmentId))
        ? widget.selectedAssignmentId
        : null;

    final AssignmentModel? selectedAssignment =
        validAssignmentId != null ? assignmentMap[validAssignmentId] : null;

    // Submissions scoped by course & assignment
    final List<AssignmentSubmissionModel> scopedSubmissions;
    if (validAssignmentId != null) {
      scopedSubmissions =
          widget.submissions.where((s) => s.assignmentId == validAssignmentId).toList();
    } else if (validCourseId != null) {
      final courseAssignIds = filteredAssignments.map((a) => a.assignmentId).toSet();
      scopedSubmissions = widget.submissions
          .where((s) => s.assignmentId != null && courseAssignIds.contains(s.assignmentId))
          .toList();
    } else {
      scopedSubmissions = List<AssignmentSubmissionModel>.from(widget.submissions);
    }

    final totalCount = scopedSubmissions.length;
    final pendingCount = scopedSubmissions.where((s) => !s.isGraded).length;
    final gradedCount = scopedSubmissions.where((s) => s.isGraded).length;

    final List<AssignmentSubmissionModel> filteredSubmissions;
    if (_submissionStatusFilter == 'PENDING') {
      filteredSubmissions = scopedSubmissions.where((s) => !s.isGraded).toList();
    } else if (_submissionStatusFilter == 'GRADED') {
      filteredSubmissions = scopedSubmissions.where((s) => s.isGraded).toList();
    } else {
      filteredSubmissions = scopedSubmissions;
    }

    final courseScopedSubmissionsCount = validCourseId != null
        ? widget.submissions
            .where((s) =>
                s.assignmentId != null &&
                filteredAssignments.any((a) => a.assignmentId == s.assignmentId))
            .length
        : widget.submissions.length;

    final hasActiveFilters = validCourseId != null ||
        validAssignmentId != null ||
        _submissionStatusFilter != 'ALL';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Card: Course Dropdown, Assignment Dropdown, and Status Chips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFF1F3F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (courseMap.isNotEmpty) ...[
                DropdownButtonFormField<int?>(
                  key: ValueKey('assign_course_dropdown_$validCourseId'),
                  initialValue: validCourseId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Filter by Course',
                    prefixIcon: const Icon(Icons.school_outlined, size: 20),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8F9FD),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        'All Courses (${widget.assignments.length} assignments)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...courseMap.entries.map((entry) {
                      final count = widget.assignments
                          .where((a) => a.courseId == entry.key)
                          .length;
                      return DropdownMenuItem<int?>(
                        value: entry.key,
                        child: Text(
                          '${entry.value} ($count)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (courseId) {
                    setState(() => _selectedAssignmentCourseId = courseId);
                    if (widget.selectedAssignmentId != null) {
                      final stillInCourse = widget.assignments.any((a) =>
                          a.assignmentId == widget.selectedAssignmentId &&
                          (courseId == null || a.courseId == courseId));
                      if (!stillInCourse) {
                        widget.onSelectAssignment(null);
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (filteredAssignments.isNotEmpty) ...[
                DropdownButtonFormField<int?>(
                  key: ValueKey('assign_item_dropdown_${validCourseId}_$validAssignmentId'),
                  initialValue: validAssignmentId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Select Assignment',
                    prefixIcon: const Icon(Icons.assignment_outlined, size: 20),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8F9FD),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        'All Assignments ($courseScopedSubmissionsCount submissions)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...filteredAssignments.map((a) {
                      final subCount = widget.submissions
                          .where((s) => s.assignmentId == a.assignmentId)
                          .length;
                      return DropdownMenuItem<int?>(
                        value: a.assignmentId,
                        child: Text(
                          '${a.title} ($subCount)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (id) => widget.onSelectAssignment(id),
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text('All ($totalCount)'),
                    selected: _submissionStatusFilter == 'ALL',
                    onSelected: (_) =>
                        setState(() => _submissionStatusFilter = 'ALL'),
                  ),
                  ChoiceChip(
                    label: Text('Pending ($pendingCount)'),
                    selected: _submissionStatusFilter == 'PENDING',
                    onSelected: (_) =>
                        setState(() => _submissionStatusFilter = 'PENDING'),
                  ),
                  ChoiceChip(
                    label: Text('Graded ($gradedCount)'),
                    selected: _submissionStatusFilter == 'GRADED',
                    onSelected: (_) =>
                        setState(() => _submissionStatusFilter = 'GRADED'),
                  ),
                  if (hasActiveFilters)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedAssignmentCourseId = null;
                          _submissionStatusFilter = 'ALL';
                        });
                        widget.onSelectAssignment(null);
                      },
                      child: const Text('Clear Filters'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Selected Assignment Details Card (when specific assignment is chosen)
        if (selectedAssignment != null) ...[
          _buildSelectedAssignmentCard(
            isDark,
            selectedAssignment,
            courseMap: courseMap,
          ),
          const SizedBox(height: 14),
        ] else if (filteredAssignments.isNotEmpty) ...[
          // Collapsible assignment overview so instructors can manage assignments too
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFF1F3F6)),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              initiallyExpanded: widget.submissions.isEmpty,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                'Course Assignments (${filteredAssignments.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF11142D),
                ),
              ),
              subtitle: Text(
                'Tap an assignment to filter or edit details',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              children: filteredAssignments.map((a) {
                final assignSubs = widget.submissions
                    .where((s) => s.assignmentId == a.assignmentId)
                    .toList();
                final assignPending = assignSubs.where((s) => !s.isGraded).length;
                final courseTitle = a.courseTitle ??
                    (a.courseId != null ? courseMap[a.courseId!] : null);

                return ListTile(
                  dense: true,
                  onTap: () => widget.onSelectAssignment(a.assignmentId),
                  title: Text(
                    a.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF11142D),
                    ),
                  ),
                  subtitle: Text(
                    [
                      if (courseTitle != null && courseTitle.isNotEmpty) courseTitle,
                      if (a.sectionTitle != null && a.sectionTitle!.isNotEmpty)
                        a.sectionTitle!,
                      '${assignSubs.length} sub${assignSubs.length == 1 ? '' : 's'}',
                      if (assignPending > 0) '$assignPending pending',
                      'Max ${a.maxScore} pts',
                    ].join(' • '),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onEditAssignment != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit Assignment',
                          onPressed: () => widget.onEditAssignment!(a),
                        ),
                      if (widget.onDeleteAssignment != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          tooltip: 'Delete Assignment',
                          onPressed: () => widget.onDeleteAssignment!(a),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Submissions List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Student Submissions (${filteredSubmissions.length})',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF11142D),
              ),
            ),
            if (pendingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pendingCount awaiting grade',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (filteredSubmissions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: EmptyState(
              title: 'No student submissions',
              description: _submissionStatusFilter != 'ALL' || validAssignmentId != null
                  ? 'No submissions match the selected filters.'
                  : 'Student assignments will appear here once submitted for grading and review.',
            ),
          )
        else
          ...filteredSubmissions.map((s) {
            final assignment =
                s.assignmentId != null ? assignmentMap[s.assignmentId!] : selectedAssignment;
            final courseTitle = assignment?.courseTitle ??
                (assignment?.courseId != null ? courseMap[assignment!.courseId!] : null);
            return _buildSubmissionCard(
              isDark,
              s,
              assignment: assignment,
              courseTitle: courseTitle,
            );
          }),
      ],
    );
  }

  Widget _buildSelectedAssignmentCard(
    bool isDark,
    AssignmentModel assignment, {
    required Map<int, String> courseMap,
  }) {
    final courseTitle = assignment.courseTitle ??
        (assignment.courseId != null ? courseMap[assignment.courseId!] : null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2F66F6).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF11142D),
                      ),
                    ),
                    if (courseTitle != null ||
                        (assignment.sectionTitle != null &&
                            assignment.sectionTitle!.isNotEmpty)) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (courseTitle != null && courseTitle.isNotEmpty) courseTitle,
                          if (assignment.sectionTitle != null &&
                              assignment.sectionTitle!.isNotEmpty)
                            assignment.sectionTitle!,
                        ].join(' • '),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.onEditAssignment != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit Assignment',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => widget.onEditAssignment!(assignment),
                ),
              if (widget.onDeleteAssignment != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  tooltip: 'Delete Assignment',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => widget.onDeleteAssignment!(assignment),
                ),
              ],
            ],
          ),
          if (assignment.description != null &&
              assignment.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              assignment.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMetaBadge(
                isDark,
                icon: Icons.score_outlined,
                label: 'Max ${assignment.maxScore} pts',
              ),
              if (assignment.dueDate != null)
                _buildMetaBadge(
                  isDark,
                  icon: Icons.schedule,
                  label: 'Due: ${_formatDateTime(assignment.dueDate)}',
                ),
              _buildMetaBadge(
                isDark,
                icon: Icons.refresh,
                label: assignment.allowResubmission
                    ? 'Resubmit allowed'
                    : 'Single submission',
              ),
            ],
          ),
          if (assignment.supportingFileUrl != null &&
              assignment.supportingFileUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openExternalFile(assignment.supportingFileUrl!),
              icon: const Icon(Icons.attach_file, size: 15),
              label: const Text(
                'Supporting File',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaBadge(
    bool isDark, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[300] : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(
    bool isDark,
    AssignmentSubmissionModel s, {
    AssignmentModel? assignment,
    String? courseTitle,
  }) {
    final isGraded = s.isGraded;
    final isLate = s.status == 'LATE';
    final isReviewed = s.status == 'REVIEWED';

    final Color badgeColor;
    final String badgeLabel;
    if (isGraded) {
      badgeColor = const Color(0xFF10B981);
      badgeLabel = 'Graded';
    } else if (isReviewed) {
      badgeColor = const Color(0xFF2563EB);
      badgeLabel = 'Reviewed';
    } else if (isLate) {
      badgeColor = const Color(0xFFDC2626);
      badgeLabel = 'Late';
    } else {
      badgeColor = const Color(0xFFD97706);
      badgeLabel = 'Submitted';
    }

    final assignmentTitle = assignment?.title ?? s.assignmentTitle ?? 'Assignment';
    final maxScore = assignment?.maxScore ?? 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFF1F3F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar, Student Name/Email, Status Badge
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: badgeColor.withValues(alpha: 0.14),
                child: Text(
                  s.studentName != null && s.studentName!.isNotEmpty
                      ? s.studentName![0].toUpperCase()
                      : 'S',
                  style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.studentName ?? 'Student',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF11142D),
                      ),
                    ),
                    if (s.studentEmail != null && s.studentEmail!.isNotEmpty)
                      Text(
                        s.studentEmail!,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Assignment & Course metadata
          Row(
            children: [
              Icon(Icons.assignment_outlined, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  courseTitle != null && courseTitle.isNotEmpty
                      ? '$assignmentTitle ($courseTitle)'
                      : assignmentTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[200] : const Color(0xFF374151),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (s.submittedAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Submitted: ${_formatDateTime(s.submittedAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],

          // Text Submission Preview
          if (s.textSubmission != null && s.textSubmission!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF8F9FD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
              ),
              child: Text(
                s.textSubmission!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[200] : const Color(0xFF374151),
                ),
              ),
            ),
          ],

          // Attached Submission File Link
          if (s.fileUrl != null && s.fileUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openExternalFile(s.fileUrl!),
              icon: const Icon(Icons.attach_file, size: 15),
              label: const Text(
                'Attached Submission File',
                style: TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],

          // Grade & Feedback Summary
          if (isGraded || (s.feedback != null && s.feedback!.trim().isNotEmpty)) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isGraded)
                    Text(
                      'Score: ${_formatScore(s.score ?? 0)} / $maxScore pts${s.grade != null && s.grade!.isNotEmpty ? ' (Grade ${s.grade})' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  if (s.feedback != null && s.feedback!.trim().isNotEmpty) ...[
                    if (isGraded) const SizedBox(height: 4),
                    Text(
                      'Feedback: ${s.feedback}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[200] : const Color(0xFF374151),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          // Action Button Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => widget.onOpenGrading(s),
                icon: Icon(
                  isGraded ? Icons.edit_outlined : Icons.grading_rounded,
                  size: 16,
                ),
                label: Text(
                  isGraded ? 'Edit Grade' : 'Grade',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  backgroundColor:
                      isGraded ? const Color(0xFF10B981) : const Color(0xFF2F66F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Students Section
  Widget _buildStudentsSection(bool isDark) {
    if (widget.enrolledStudents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: EmptyState(
          title: 'No enrolled students yet',
          description: 'Students who enroll in your courses will be listed here with real-time progress.',
        ),
      );
    }

    // Extract unique classes/courses from widget.courses and widget.enrolledStudents
    final Map<int, String> classMap = {};
    for (final c in widget.courses) {
      classMap[c.courseId] = c.title;
    }
    for (final e in widget.enrolledStudents) {
      if (!classMap.containsKey(e.courseId)) {
        classMap[e.courseId] = e.courseTitle.isNotEmpty ? e.courseTitle : 'Course #${e.courseId}';
      }
    }

    final validSelectedClassId = classMap.containsKey(_selectedClassId) ? _selectedClassId : null;

    // Filter students by class and search query
    var filteredStudents = widget.enrolledStudents;
    if (validSelectedClassId != null) {
      filteredStudents = filteredStudents.where((e) => e.courseId == validSelectedClassId).toList();
    }
    if (_studentSearchQuery.trim().isNotEmpty) {
      final q = _studentSearchQuery.trim().toLowerCase();
      filteredStudents = filteredStudents.where((e) {
        final name = (e.userName ?? '').toLowerCase();
        final email = (e.userEmail ?? '').toLowerCase();
        final course = e.courseTitle.toLowerCase();
        return name.contains(q) || email.contains(q) || course.contains(q);
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Card: Class Dropdown and Student Search
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFF1F3F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Class / Course',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF11142D),
                ),
              ),
              const SizedBox(height: 8),
              // Class Dropdown
              DropdownButtonFormField<int?>(
                key: ValueKey('enrolled_students_class_dropdown_$validSelectedClassId'),
                initialValue: validSelectedClassId,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.school_outlined, size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8F9FD),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2F66F6), width: 1.5),
                  ),
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      'All Classes (${widget.enrolledStudents.length} Students)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF11142D),
                      ),
                    ),
                  ),
                  ...classMap.entries.map((entry) {
                    final studentCount = widget.enrolledStudents.where((e) => e.courseId == entry.key).length;
                    return DropdownMenuItem<int?>(
                      value: entry.key,
                      child: Text(
                        '${entry.value} ($studentCount students)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF11142D),
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() => _selectedClassId = val);
                },
              ),
              const SizedBox(height: 12),
              // Search input
              TextField(
                key: const Key('enrolled_students_search_field'),
                controller: _studentSearchController,
                decoration: InputDecoration(
                  hintText: 'Search student by name or email...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _studentSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _studentSearchController.clear();
                            setState(() => _studentSearchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8F9FD),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2F66F6), width: 1.5),
                  ),
                ),
                onChanged: (val) {
                  setState(() => _studentSearchQuery = val);
                },
              ),
              if (validSelectedClassId != null || _studentSearchQuery.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtered: ${filteredStudents.length} of ${widget.enrolledStudents.length} students',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedClassId = null;
                          _studentSearchQuery = '';
                          _studentSearchController.clear();
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: Text(
                          'Clear Filters',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F66F6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Students Table
        if (filteredStudents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFF1F3F6)),
            ),
            child: Column(
              children: [
                Icon(Icons.person_search_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No students found',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF11142D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No enrolled students match the selected class or search query.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedClassId = null;
                      _studentSearchQuery = '';
                      _studentSearchController.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset Filter'),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFF1F3F6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: DataTable(
                headingRowHeight: 48,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 68,
                horizontalMargin: 16,
                columnSpacing: 24,
                headingRowColor: WidgetStateProperty.all(
                  isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      '#',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Student Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Class / Course',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
                rows: filteredStudents.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final student = entry.value;
                  final isCompleted = student.status == 'COMPLETED';
                  final isActive = student.status == 'ACTIVE';

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '$index',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF3B67F6).withValues(alpha: 0.15),
                              child: Text(
                                student.userName != null && student.userName!.isNotEmpty
                                    ? student.userName![0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF3B67F6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  student.userName ?? 'Student',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : const Color(0xFF11142D),
                                  ),
                                ),
                                if (student.userEmail != null && student.userEmail!.isNotEmpty)
                                  Text(
                                    student.userEmail!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(
                            student.courseTitle.isNotEmpty ? student.courseTitle : 'Course #${student.courseId}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[200] : const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 60,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (student.progressPercent / 100).clamp(0.0, 1.0),
                                  backgroundColor: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                                  color: student.progressPercent >= 100
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF3B67F6),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${student.progressPercent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: student.progressPercent >= 100
                                    ? const Color(0xFF10B981)
                                    : (isDark ? Colors.grey[300] : const Color(0xFF374151)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : (isActive
                                    ? const Color(0xFF3B67F6).withValues(alpha: 0.15)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            student.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? const Color(0xFF10B981)
                                  : (isActive ? const Color(0xFF3B67F6) : const Color(0xFFF59E0B)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  // 4. Quizzes Section
  Widget _buildQuizzesSection(bool isDark) {
    final q = widget.quizReport;
    if (q == null || q.quizSummaries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: EmptyState(
          title: 'No quizzes configured',
          description: 'Add quizzes and tests inside your course materials to assess student comprehension.',
        ),
      );
    }

    return Column(
      children: q.quizSummaries.map((qs) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFF1F3F6)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.quiz_rounded, color: Color(0xFF059669), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qs.quizTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF11142D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Attempts: ${qs.totalAttempts} • Avg Score: ${qs.averageScore.toStringAsFixed(1)} pts',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${qs.passRate.toStringAsFixed(0)}% Pass',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
