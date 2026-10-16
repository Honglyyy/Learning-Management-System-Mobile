import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_state.dart';
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

    final gradedCount = widget.submissions.where((s) => s.status == 'GRADED').length;
    final gradedPercent = widget.submissions.isNotEmpty ? (gradedCount / widget.submissions.length) : 0.8;

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
            // Top App Bar: Back Button, Title 'Course & Materials Studio', New Course Button
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
                Text(
                  _getTabTitle(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF11142D),
                  ),
                ),
                if (_activeTab == ManageStudioTab.curriculum)
                  Text(
                    '${widget.courses.length} courses',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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

  // 2. Assignments & Grading Section
  Widget _buildAssignmentsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.assignments.isNotEmpty) ...[
          DropdownButtonFormField<int>(
            initialValue: widget.selectedAssignmentId,
            decoration: InputDecoration(
              labelText: 'Select Assignment to Review',
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: widget.assignments.map((a) {
              return DropdownMenuItem(
                value: a.assignmentId,
                child: Text(a.title, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (id) => widget.onSelectAssignment(id),
          ),
          const SizedBox(height: 14),
        ],

        if (widget.submissions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: EmptyState(
              title: 'No student submissions',
              description: 'Student assignments will appear here for grading and review.',
            ),
          )
        else
          ...widget.submissions.map((s) {
            final isGraded = s.status == 'GRADED';
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
                  CircleAvatar(
                    backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    child: Text(
                      s.studentName != null && s.studentName!.isNotEmpty ? s.studentName![0].toUpperCase() : 'S',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
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
                        const SizedBox(height: 2),
                        Text(
                          isGraded
                              ? 'Score: ${s.score ?? 0} (${s.grade ?? "A"}) • Graded'
                              : 'Status: Pending Grading',
                          style: TextStyle(
                            fontSize: 12,
                            color: isGraded ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            fontWeight: isGraded ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => widget.onOpenGrading(s),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      backgroundColor: isGraded ? const Color(0xFF10B981) : const Color(0xFF2F66F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(isGraded ? 'Edit Grade' : 'Grade', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            );
          }),
      ],
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
