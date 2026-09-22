import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/assignment_model.dart';
import '../../../models/course_model.dart';
import '../../../models/lesson_model.dart';
import '../../payments/widgets/aba_payway_dialog.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final int courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CourseModel? _course;
  List<AssignmentModel> _assignments = [];
  List<CourseReview> _reviews = [];
  List<int> _completedLessonIds = [];
  double _progressPercent = 0.0;
  bool _isEnrolled = false;

  bool _isLoading = true;
  String? _error;

  // Review Form
  int _newReviewRating = 5;
  final TextEditingController _newReviewController = TextEditingController();
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadCourseData();
  }

  void _handleTabSelection() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _newReviewController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final courseRepo = ref.read(courseRepositoryProvider);
      final assignmentRepo = ref.read(assignmentRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);

      final course = await courseRepo.getCourseById(widget.courseId);
      final assignments = await assignmentRepo.getCourseAssignments(widget.courseId).catchError((_) => <AssignmentModel>[]);
      final reviews = await courseRepo.getReviews(widget.courseId).catchError((_) => <CourseReview>[]);

      bool isEnrolled = false;
      double progress = 0.0;
      List<int> completedIds = [];

      if (authRepo.isAuthenticated) {
        try {
          final myEnrollments = await ref.read(enrollmentRepositoryProvider).getMyEnrollments();
          final matching = myEnrollments.where((e) => e.courseId == widget.courseId).toList();
          if (matching.isNotEmpty) {
            isEnrolled = true;
            progress = matching.first.progressPercent;
            completedIds = await courseRepo.getLessonsStatus(widget.courseId).catchError((_) => <int>[]);
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _course = course;
          _assignments = assignments;
          _reviews = reviews;
          _isEnrolled = isEnrolled;
          _progressPercent = progress;
          _completedLessonIds = completedIds;
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

  Future<void> _handleFreeEnroll() async {
    final authRepo = ref.read(authRepositoryProvider);
    if (!authRepo.isAuthenticated) {
      context.push('/login');
      return;
    }

    try {
      final paymentRepo = ref.read(paymentRepositoryProvider);
      final checkout = await paymentRepo.checkout(widget.courseId);
      await paymentRepo.confirmPayment(checkout.paymentId);
      ToastService.showSuccess('Enrolled successfully!');
      _loadCourseData();
    } catch (e) {
      ToastService.showError(e.toString());
    }
  }

  Future<void> _handleClaimCertificate() async {
    try {
      final certRepo = ref.read(certificateRepositoryProvider);
      final cert = await certRepo.claimCertificate(widget.courseId);
      ToastService.showSuccess('Certificate Claimed! Code: ${cert.certificateCode}');
      if (mounted) {
        context.push('/verify-certificate?code=${cert.certificateCode}');
      }
    } catch (e) {
      ToastService.showError(e.toString());
    }
  }

  Future<void> _submitReview() async {
    if (_newReviewController.text.trim().isEmpty) return;

    setState(() => _isSubmittingReview = true);
    try {
      final courseRepo = ref.read(courseRepositoryProvider);
      await courseRepo.submitReview(widget.courseId, _newReviewRating, _newReviewController.text.trim());
      _newReviewController.clear();
      ToastService.showSuccess('Review submitted!');
      final updatedReviews = await courseRepo.getReviews(widget.courseId);
      if (mounted) {
        setState(() {
          _reviews = updatedReviews;
          _isSubmittingReview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(e.toString());
        setState(() => _isSubmittingReview = false);
      }
    }
  }

  void _showPayToUnlockSheet(LessonModel lesson) {
    if (_course == null) return;
    final theme = Theme.of(context);
    final isCourseFree = _course!.isFree;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Unlock This Lesson',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lesson.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  isCourseFree
                      ? 'This lesson is locked. Enroll in this free course to unlock all lessons.'
                      : 'This lesson is locked. Purchase the full course to get instant access to all video lessons, quizzes, and certificates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.hintColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Full Course Access',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _course!.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isCourseFree ? 'Free' : Formatters.formatCurrency(_course!.price),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      final authRepo = ref.read(authRepositoryProvider);
                      if (!authRepo.isAuthenticated) {
                        ToastService.showInfo('Please log in to continue.');
                        context.push('/login');
                        return;
                      }

                      if (isCourseFree) {
                        _handleFreeEnroll();
                      } else {
                        AbaPayWayDialog.show(
                          context,
                          courseId: _course!.courseId,
                          courseTitle: _course!.title,
                          price: _course!.price,
                        );
                      }
                    },
                    child: Text(
                      isCourseFree
                          ? 'Enroll Now (Free)'
                          : 'Pay to Unlock • ${Formatters.formatCurrency(_course!.price)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Maybe Later'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurriculumTab() {
    if (_course == null || _course!.sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: EmptyState(
          title: 'No sections published yet',
          description: 'The curriculum sections and lessons for this course will appear here once published.',
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _course!.sections.length,
      itemBuilder: (context, sIndex) {
        final sec = _course!.sections[sIndex];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            initiallyExpanded: sIndex == 0,
            title: Text(
              sec.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${sec.lessons.length} lessons ${sec.duration != null ? "• ${sec.duration}" : ""}',
              style: const TextStyle(fontSize: 12),
            ),
            children: sec.lessons.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'No lessons published in this section yet.',
                            style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ]
                : sec.lessons.map((lesson) {
              final isUnlocked = _isEnrolled || lesson.isFree;
              final isDone = _completedLessonIds.contains(lesson.lessonId);

              return ListTile(
                dense: true,
                leading: Icon(
                  isDone
                      ? Icons.check_circle
                      : isUnlocked
                          ? Icons.play_circle_outline
                          : Icons.lock_outline,
                  color: isDone
                      ? Colors.green
                      : isUnlocked
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                  size: 22,
                ),
                title: Text(
                  lesson.title,
                  style: TextStyle(
                    fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.normal,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
                subtitle: Text(
                  lesson.duration ?? 'Video lesson',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: lesson.isFree
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Preview',
                          style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      )
                    : null,
                onTap: () {
                  if (isUnlocked) {
                    context.push('/courses/${widget.courseId}/lessons/${lesson.lessonId}');
                  } else {
                    _showPayToUnlockSheet(lesson);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsTab() {
    if (_assignments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: EmptyState(title: 'No assignments for this course'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        final a = _assignments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.assignment_outlined, size: 20)),
            title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              'Max score: ${a.maxScore} points ${a.dueDate != null ? "• Due: ${Formatters.formatDate(a.dueDate)}" : ""}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/assignments/${a.assignmentId}'),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isEnrolled) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Write a Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _newReviewRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => setState(() => _newReviewRating = index + 1),
                      );
                    }),
                  ),
                  TextField(
                    controller: _newReviewController,
                    decoration: const InputDecoration(
                      hintText: 'Share your thoughts on this course...',
                      isDense: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isSubmittingReview ? null : _submitReview,
                    child: _isSubmittingReview
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Review'),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: EmptyState(title: 'No reviews yet', description: 'Be the first to review this course.'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              final r = _reviews[index];
              final reviewerName = r.userName ?? 'Anonymous';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            child: Text(reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'U'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(reviewerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(Formatters.timeAgo(r.createdAt), style: TextStyle(fontSize: 10, color: theme.hintColor)),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(5, (i) => Icon(
                              i < r.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 14,
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(r.reviewText, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final c = _course!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('About This Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(c.description, style: const TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 20),
        if (c.learningOutcomesList.isNotEmpty) ...[
          const Text('What You\'ll Learn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...c.learningOutcomesList.map((outcome) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(outcome, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
          const SizedBox(height: 20),
        ],
        if (c.requirementsList.isNotEmpty) ...[
          const Text('Requirements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...c.requirementsList.map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.fiber_manual_record, size: 10),
                    const SizedBox(width: 10),
                    Expanded(child: Text(req, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildStickyBottomBar(ThemeData theme) {
    if (_course == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Price', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(
                  Formatters.formatCurrency(_course!.price),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isEnrolled
                  ? _progressPercent >= 100.0
                      ? ElevatedButton.icon(
                          icon: const Icon(Icons.verified, size: 18),
                          label: const Text('Claim Certificate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _handleClaimCertificate,
                        )
                      : ElevatedButton(
                          onPressed: () {
                            if (_course!.sections.isNotEmpty &&
                                _course!.sections.first.lessons.isNotEmpty) {
                              context.push(
                                '/courses/${widget.courseId}/lessons/${_course!.sections.first.lessons.first.lessonId}',
                              );
                            }
                          },
                          child: Text('Continue Learning (${Formatters.formatProgress(_progressPercent)})'),
                        )
                  : ElevatedButton(
                      onPressed: () {
                        if (_course!.isFree) {
                          _handleFreeEnroll();
                        } else {
                          AbaPayWayDialog.show(
                            context,
                            courseId: _course!.courseId,
                            courseTitle: _course!.title,
                            price: _course!.price,
                          );
                        }
                      },
                      child: Text(_course!.isFree ? 'Enroll Now (Free)' : 'Buy Now'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Congratulations!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have successfully completed "${_course?.title ?? "this course"}"! 🎉',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.verified, color: Colors.green, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All lessons, quizzes, and course requirements are complete. Claim your official verified certificate now!',
                      style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.workspace_premium, size: 18),
            label: const Text('Claim Certificate'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleClaimCertificate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBreakdownCard(ThemeData theme) {
    if (!_isEnrolled || _course == null) return const SizedBox.shrink();

    final totalLessons = _course!.sections.fold<int>(0, (sum, sec) => sum + sec.lessons.length);
    final completedLessons = _completedLessonIds.length;
    final totalAssignments = _assignments.length;

    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _progressPercent >= 100.0
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _progressPercent >= 100.0
              ? Colors.green
              : theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _progressPercent >= 100.0 ? Icons.verified : Icons.trending_up,
                color: _progressPercent >= 100.0 ? Colors.green : theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _progressPercent >= 100.0 ? 'Course Completed! 🎉' : 'Your Learning Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _progressPercent >= 100.0 ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
              ),
              Text(
                '${_progressPercent.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_progressPercent / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                _progressPercent >= 100.0 ? Colors.green : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressStat(
                icon: Icons.menu_book,
                label: 'Lessons Done',
                value: '$completedLessons / $totalLessons',
              ),
              _buildProgressStat(
                icon: Icons.assignment_outlined,
                label: 'Assignments',
                value: '$totalAssignments',
              ),
              if (_progressPercent >= 100.0)
                InkWell(
                  onTap: _showCompletionDialog,
                  child: _buildProgressStat(
                    icon: Icons.workspace_premium,
                    label: 'Certificate',
                    value: 'Claim Now',
                    valueColor: Colors.green,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: valueColor ?? Colors.grey),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Listen to reactive progress updates
    ref.listen<int>(courseProgressRefreshProvider, (prev, next) {
      _loadCourseData();
    });

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              LoadingSkeleton(width: double.infinity, height: 200),
              SizedBox(height: 16),
              LoadingSkeleton(width: double.infinity, height: 24),
              SizedBox(height: 8),
              LoadingSkeleton(width: 200, height: 16),
            ],
          ),
        ),
      );
    }

    if (_error != null || _course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ApiAlert(error: _error ?? 'Failed to load course details', onRetry: _loadCourseData),
          ),
        ),
      );
    }

    final c = _course!;
    final cover = mediaUrl(c.coverUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(c.isFavorite ? Icons.favorite : Icons.favorite_border, color: c.isFavorite ? Colors.red : null),
            onPressed: () async {
              final courseRepo = ref.read(courseRepositoryProvider);
              if (c.isFavorite) {
                await courseRepo.removeFavorite(c.courseId);
              } else {
                await courseRepo.addFavorite(c.courseId);
              }
              _loadCourseData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            SizedBox(
              height: 200,
              width: double.infinity,
              child: _buildCoverImageWidget(cover, c.title),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c.level.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (c.overallDuration != null)
                        Text(
                          c.overallDuration!,
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(c.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('(${c.reviews.length} reviews)'),
                      const SizedBox(width: 12),
                      const Icon(Icons.people_outline, size: 18),
                      const SizedBox(width: 4),
                      Text('${c.enrollmentCount} students'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (c.instructor != null) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          child: Text(c.instructor![0].toUpperCase()),
                        ),
                        const SizedBox(width: 8),
                        Text('Instructor: ${c.instructor!}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            _buildProgressBreakdownCard(theme),
            TabBar(
              controller: _tabController,
              onTap: (index) {
                if (mounted) setState(() {});
              },
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Curriculum'),
                Tab(text: 'Assignments'),
                Tab(text: 'Reviews'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildCurrentTab(),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildStickyBottomBar(theme),
    );
  }

  Widget _buildCoverImageWidget(String cover, String title) {
    if (cover.isEmpty) {
      return Container(
        color: const Color(0xFF1E293B),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 56, color: Colors.white54),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: cover,
      fit: BoxFit.cover,
      placeholder: (context, _) => Container(
        color: const Color(0xFF1E293B),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white54),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFF1E293B),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 56, color: Colors.white54),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_tabController.index) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildCurriculumTab();
      case 2:
        return _buildAssignmentsTab();
      case 3:
        return _buildReviewsTab();
      default:
        return _buildOverviewTab();
    }
  }
}
