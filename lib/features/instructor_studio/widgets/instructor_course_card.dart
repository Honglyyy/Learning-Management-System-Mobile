import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/course_model.dart';
import '../../../models/lesson_model.dart';
import '../../../models/quiz_model.dart';
import '../../../models/section_model.dart';
import 'course_form_dialog.dart';
import 'lesson_form_dialog.dart';
import 'lesson_video_preview_dialog.dart';
import 'quiz_content_dialogs.dart';
import 'section_form_dialog.dart';

class InstructorCourseCard extends ConsumerStatefulWidget {
  final CourseModel course;
  final VoidCallback onCourseMutated;

  const InstructorCourseCard({
    super.key,
    required this.course,
    required this.onCourseMutated,
  });

  @override
  ConsumerState<InstructorCourseCard> createState() => _InstructorCourseCardState();
}

class _InstructorCourseCardState extends ConsumerState<InstructorCourseCard> {
  bool _isExpanded = false;
  bool _isLoadingMaterials = false;
  bool _isTogglingStatus = false;

  List<SectionModel> _sections = [];
  List<LessonModel> _lessons = [];
  List<QuizModel> _quizzes = [];
  List<QuestionModel> _questions = [];
  List<AnswerModel> _answers = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadCourseMaterials() async {
    setState(() => _isLoadingMaterials = true);
    try {
      final sectionRepo = ref.read(sectionRepositoryProvider);
      final lessonRepo = ref.read(lessonRepositoryProvider);
      final quizRepo = ref.read(quizRepositoryProvider);

      final sectionsFuture = sectionRepo.getInstructorSections(courseId: widget.course.courseId);
      final lessonsFuture = lessonRepo.getInstructorLessons(courseId: widget.course.courseId);
      final quizzesFuture = quizRepo.getQuizzes();
      final questionsFuture = quizRepo.getQuestions();
      final answersFuture = quizRepo.getAnswers();

      final results = await Future.wait([
        sectionsFuture,
        lessonsFuture,
        quizzesFuture,
        questionsFuture,
        answersFuture,
      ]);

      if (mounted) {
        setState(() {
          _sections = results[0] as List<SectionModel>;
          _lessons = results[1] as List<LessonModel>;
          final allQuizzes = results[2] as List<QuizModel>;
          final allQuestions = results[3] as List<QuestionModel>;
          final allAnswers = results[4] as List<AnswerModel>;

          final lessonIds = _lessons.map((l) => l.lessonId).toSet();
          _quizzes = allQuizzes.where((q) => lessonIds.contains(q.lessonId)).toList();
          final quizIds = _quizzes.map((q) => q.quizId).toSet();
          _questions = allQuestions.where((qn) => quizIds.contains(qn.quizId)).toList();
          final questionIds = _questions.map((qn) => qn.questionId).toSet();
          _answers = allAnswers.where((a) => questionIds.contains(a.questionId)).toList();

          _isLoadingMaterials = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMaterials = false);
      }
    }
  }

  Future<void> _toggleStatus() async {
    setState(() => _isTogglingStatus = true);
    try {
      final nextStatus = widget.course.status == 'PUBLISHED' ? 'DRAFT' : 'PUBLISHED';
      await ref.read(courseRepositoryProvider).updateCourseStatus(widget.course.courseId, nextStatus);
      ToastService.showSuccess('Status updated to $nextStatus');
      widget.onCourseMutated();
    } catch (e) {
      ToastService.showError(e.toString());
    } finally {
      if (mounted) setState(() => _isTogglingStatus = false);
    }
  }

  Future<void> _deleteCourse() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Course',
      message: 'Are you sure you want to delete "${widget.course.title}"? This cannot be undone.',
    );
    if (confirmed == true) {
      try {
        await ref.read(courseRepositoryProvider).deleteInstructorCourse(widget.course.courseId);
        ToastService.showSuccess('Course deleted');
        widget.onCourseMutated();
      } catch (e) {
        ToastService.showError(e.toString());
      }
    }
  }

  Future<void> _deleteSection(SectionModel s) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Section',
      message: 'Are you sure you want to delete "${s.title}" and all its lessons?',
    );
    if (confirmed == true) {
      try {
        await ref.read(sectionRepositoryProvider).deleteInstructorSection(s.sectionId);
        ToastService.showSuccess('Section deleted');
        _loadCourseMaterials();
      } catch (e) {
        ToastService.showError(e.toString());
      }
    }
  }

  Future<void> _deleteLesson(LessonModel l) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Lesson',
      message: 'Are you sure you want to delete "${l.title}"?',
    );
    if (confirmed == true) {
      try {
        await ref.read(lessonRepositoryProvider).deleteInstructorLesson(l.lessonId);
        ToastService.showSuccess('Lesson deleted');
        _loadCourseMaterials();
      } catch (e) {
        ToastService.showError(e.toString());
      }
    }
  }

  Future<void> _deleteQuiz(int quizId) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Quiz',
      message: 'Delete this quiz and all its questions?',
    );
    if (confirmed == true) {
      try {
        await ref.read(quizRepositoryProvider).deleteQuiz(quizId);
        ToastService.showSuccess('Quiz deleted');
        _loadCourseMaterials();
      } catch (e) {
        ToastService.showError(e.toString());
      }
    }
  }

  Future<void> _deleteQuestion(int questionId) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Question',
      message: 'Delete this question and its answers?',
    );
    if (confirmed == true) {
      try {
        await ref.read(quizRepositoryProvider).deleteQuestion(questionId);
        ToastService.showSuccess('Question deleted');
        _loadCourseMaterials();
      } catch (e) {
        ToastService.showError(e.toString());
      }
    }
  }

  Future<void> _deleteAnswer(int answerId) async {
    try {
      await ref.read(quizRepositoryProvider).deleteAnswer(answerId);
      ToastService.showSuccess('Answer deleted');
      _loadCourseMaterials();
    } catch (e) {
      ToastService.showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final theme = Theme.of(context);
    final isPublished = c.status == 'PUBLISHED';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
          if (expanded) {
            _loadCourseMaterials();
          }
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 54,
            height: 54,
            child: (c.coverUrl != null && c.coverUrl!.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: mediaUrl(c.coverUrl),
                    fit: BoxFit.cover,
                    placeholder: (ctx, _) => Container(color: Colors.grey[200]),
                    errorWidget: (ctx, _, __) => Container(
                      color: theme.colorScheme.primaryContainer,
                      child: Center(
                        child: Text(
                          c.title.isNotEmpty ? c.title[0].toUpperCase() : 'C',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: theme.colorScheme.primaryContainer,
                    child: Center(
                      child: Text(
                        c.title.isNotEmpty ? c.title[0].toUpperCase() : 'C',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                c.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges & Toggle Row
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPublished ? Colors.green[50] : Colors.amber[50],
                      border: Border.all(
                        color: isPublished ? Colors.green[300]! : Colors.amber[300]!,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      c.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPublished ? Colors.green[800] : Colors.amber[900],
                      ),
                    ),
                  ),

                  // Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      c.level.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  // Publish/Unpublish Toggle Button
                  InkWell(
                    onTap: _isTogglingStatus ? null : _toggleStatus,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _isTogglingStatus
                            ? '...'
                            : (isPublished ? 'Unpublish' : 'Publish'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),

                  // Category Badges
                  ...c.categories.take(3).map((cat) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 6),

              // Price, duration, rating, enrollment summary
              Row(
                children: [
                  Text(
                    Formatters.formatCurrency(c.price),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (c.overallDuration != null && c.overallDuration!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    Icon(Icons.schedule, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(c.overallDuration!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                  if (c.rating > 0) ...[
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(c.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(width: 8),
                  const Text('•', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  Text('${c.enrollmentCount} enrolled', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Edit Course',
              onPressed: () {
                CourseFormDialog.show(
                  context,
                  course: c,
                  onSaved: widget.onCourseMutated,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              tooltip: 'Delete Course',
              onPressed: _deleteCourse,
            ),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),

                // Course description
                if (c.description.isNotEmpty) ...[
                  Text(
                    c.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── SECTIONS ACCORDION ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SECTIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Colors.grey,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        SectionFormDialog.show(
                          context,
                          courseId: c.courseId,
                          onSaved: _loadCourseMaterials,
                        );
                      },
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add Section', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_isLoadingMaterials)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_sections.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: const Center(
                      child: Text('No sections yet. Click "Add Section" to create one.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sections.length,
                    itemBuilder: (context, sIdx) {
                      final section = _sections[sIdx];
                      final sectionLessons = _lessons
                          .where((l) => l.sectionId == section.sectionId)
                          .toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  section.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                              if (section.duration != null && section.duration!.isNotEmpty) ...[
                                Text(
                                  section.duration!,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                '${sectionLessons.length} lesson${sectionLessons.length != 1 ? "s" : ""}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                tooltip: 'Edit Section',
                                onPressed: () {
                                  SectionFormDialog.show(
                                    context,
                                    courseId: c.courseId,
                                    section: section,
                                    onSaved: _loadCourseMaterials,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                tooltip: 'Delete Section',
                                onPressed: () => _deleteSection(section),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),

                                  // Lessons list
                                  if (sectionLessons.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text(
                                        'No lessons in this section.',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    )
                                  else
                                    ...sectionLessons.map((l) {
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.play_circle_outline, size: 16, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      l.title,
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (l.isFree) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green[50],
                                                        border: Border.all(color: Colors.green[300]!),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        'Free Trial',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.green[800],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (l.duration != null && l.duration!.isNotEmpty) ...[
                                              Text(l.duration!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                              const SizedBox(width: 6),
                                            ],

                                            // Play video button
                                            if (l.playableVideoUrl.isNotEmpty)
                                              IconButton(
                                                icon: const Icon(Icons.smart_display_outlined, size: 18, color: Colors.blue),
                                                tooltip: 'Preview Video',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () {
                                                  LessonVideoPreviewDialog.show(
                                                    context,
                                                    title: l.title,
                                                    videoUrl: l.playableVideoUrl,
                                                  );
                                                },
                                              ),
                                            const SizedBox(width: 8),

                                            // Edit lesson
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 16),
                                              tooltip: 'Edit Lesson',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                LessonFormDialog.show(
                                                  context,
                                                  sectionId: section.sectionId,
                                                  courseId: c.courseId,
                                                  lesson: l,
                                                  onSaved: _loadCourseMaterials,
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 8),

                                            // Delete lesson
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                              tooltip: 'Delete Lesson',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _deleteLesson(l),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                  const SizedBox(height: 6),
                                  // Add Lesson Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        LessonFormDialog.show(
                                          context,
                                          sectionId: section.sectionId,
                                          courseId: c.courseId,
                                          onSaved: _loadCourseMaterials,
                                        );
                                      },
                                      icon: const Icon(Icons.add, size: 14),
                                      label: const Text('Add Lesson', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 12),
                const Divider(),

                // ── QUIZ CONTENT MANAGER ACCORDION ───────────────────────────
                ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: EdgeInsets.zero,
                  title: const Text(
                    'Manage quizzes, questions, answers',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Create Buttons Row
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _lessons.isEmpty
                                      ? null
                                      : () {
                                          QuizEditDialog.show(
                                            context,
                                            lessons: _lessons,
                                            onSaved: _loadCourseMaterials,
                                          );
                                        },
                                  icon: const Icon(Icons.quiz_outlined, size: 14),
                                  label: const Text('New Quiz', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _quizzes.isEmpty
                                      ? null
                                      : () {
                                          QuestionEditDialog.show(
                                            context,
                                            quizzes: _quizzes,
                                            onSaved: _loadCourseMaterials,
                                          );
                                        },
                                  icon: const Icon(Icons.help_outline, size: 14),
                                  label: const Text('New Question', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _questions.isEmpty
                                      ? null
                                      : () {
                                          AnswerEditDialog.show(
                                            context,
                                            questions: _questions,
                                            onSaved: _loadCourseMaterials,
                                          );
                                        },
                                  icon: const Icon(Icons.check_box_outlined, size: 14),
                                  label: const Text('New Answer', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_quizzes.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text(
                                  'No quizzes yet. Create one for a lesson first.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ..._quizzes.map((quiz) {
                              final quizQuestions = _questions
                                  .where((q) => q.quizId == quiz.quizId)
                                  .toList();
                              final lesson = _lessons
                                  .cast<LessonModel?>()
                                  .firstWhere((l) => l?.lessonId == quiz.lessonId, orElse: () => null);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.colorScheme.outlineVariant),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Quiz Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                quiz.title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              Text(
                                                '${quiz.totalPoints} points • ${lesson?.title ?? "Lesson"}',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 16),
                                              tooltip: 'Edit Quiz',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                QuizEditDialog.show(
                                                  context,
                                                  quiz: quiz,
                                                  lessons: _lessons,
                                                  onSaved: _loadCourseMaterials,
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                              tooltip: 'Delete Quiz',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _deleteQuiz(quiz.quizId),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Questions under Quiz
                                    if (quizQuestions.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      ...quizQuestions.map((qn) {
                                        final qnAnswers = _answers
                                            .where((a) => a.questionId == qn.questionId)
                                            .toList();

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 6),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      qn.questionText,
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.edit_outlined, size: 14),
                                                        tooltip: 'Edit Question',
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        onPressed: () {
                                                          QuestionEditDialog.show(
                                                            context,
                                                            question: qn,
                                                            quizzes: _quizzes,
                                                            onSaved: _loadCourseMaterials,
                                                          );
                                                        },
                                                      ),
                                                      const SizedBox(width: 8),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                                        tooltip: 'Delete Question',
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        onPressed: () => _deleteQuestion(qn.questionId),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),

                                              // Answers under Question
                                              if (qnAnswers.isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                ...qnAnswers.map((ans) {
                                                  return Container(
                                                    margin: const EdgeInsets.only(bottom: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: theme.colorScheme.surface,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(
                                                        color: ans.isCorrect
                                                            ? Colors.green[300]!
                                                            : theme.colorScheme.outlineVariant,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Row(
                                                            children: [
                                                              Text(ans.answerText, style: const TextStyle(fontSize: 11)),
                                                              if (ans.isCorrect) ...[
                                                                const SizedBox(width: 6),
                                                                Text(
                                                                  '(Correct)',
                                                                  style: TextStyle(
                                                                    fontSize: 10,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.green[700],
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                        Row(
                                                          children: [
                                                            IconButton(
                                                              icon: const Icon(Icons.edit_outlined, size: 12),
                                                              tooltip: 'Edit Answer',
                                                              padding: EdgeInsets.zero,
                                                              constraints: const BoxConstraints(),
                                                              onPressed: () {
                                                                AnswerEditDialog.show(
                                                                  context,
                                                                  answer: ans,
                                                                  questions: _questions,
                                                                  onSaved: _loadCourseMaterials,
                                                                );
                                                              },
                                                            ),
                                                            const SizedBox(width: 6),
                                                            IconButton(
                                                              icon: const Icon(Icons.delete_outline, size: 12, color: Colors.red),
                                                              tooltip: 'Delete Answer',
                                                              padding: EdgeInsets.zero,
                                                              constraints: const BoxConstraints(),
                                                              onPressed: () => _deleteAnswer(ans.answerId),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
