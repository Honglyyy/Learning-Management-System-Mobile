import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/course_model.dart';
import '../../../models/lesson_model.dart';
import '../../../models/quiz_model.dart';

class LessonPlayerScreen extends ConsumerStatefulWidget {
  final int courseId;
  final int lessonId;

  const LessonPlayerScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen> {
  CourseModel? _course;
  bool _isEnrolled = false;
  LessonModel? _lesson;
  LessonNavigation? _navigation;
  LessonProgress? _progress;
  QuizModel? _quiz;
  List<LessonMaterial> _materials = [];

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Timer? _progressSaveTimer;

  bool _isLoading = true;
  bool _isVideoLoading = false;
  String? _videoError;
  bool _isMarkingComplete = false;
  bool _hasShownCompletionPrompt = false;
  bool _isLockedByPrerequisite = false;
  LessonModel? _prerequisiteLesson;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  @override
  void didUpdateWidget(covariant LessonPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonId != widget.lessonId || oldWidget.courseId != widget.courseId) {
      _disposePlayer();
      _loadLesson();
    }
  }

  void _disposePlayer() {
    _progressSaveTimer?.cancel();
    _videoController?.removeListener(_onVideoPlayerUpdate);
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.dispose();
    _videoController = null;
    _isVideoLoading = false;
    _videoError = null;
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  Future<void> _loadLesson() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasShownCompletionPrompt = false;
    });

    try {
      final lessonRepo = ref.read(lessonRepositoryProvider);
      final quizRepo = ref.read(quizRepositoryProvider);
      final courseRepo = ref.read(courseRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);

      // 1. Fetch course details to check curriculum and isFree attributes
      CourseModel? course;
      try {
        course = await courseRepo.getCourseById(widget.courseId);
      } catch (_) {}

      // 2. Check enrollment status
      bool isEnrolled = false;
      if (authRepo.isAuthenticated) {
        try {
          final myEnrollments = await ref.read(enrollmentRepositoryProvider).getMyEnrollments();
          isEnrolled = myEnrollments.any((e) => e.courseId == widget.courseId);
        } catch (_) {}
      }

      // 3. Resolve target lesson
      LessonModel? lesson;
      if (course != null) {
        for (final sec in course.sections) {
          for (final l in sec.lessons) {
            if (l.lessonId == widget.lessonId) {
              lesson = l;
              break;
            }
          }
          if (lesson != null) break;
        }
      }

      if (lesson == null) {
        try {
          lesson = await lessonRepo.getLessonById(widget.lessonId);
        } catch (e) {
          if (lesson == null) rethrow;
        }
      }

      bool isLockedByPrerequisite = false;
      LessonModel? prerequisiteLesson;

      if (isEnrolled && lesson != null && course != null) {
        final allLessons = course.sections.expand((s) => s.lessons).toList();
        final currentIdx = allLessons.indexWhere((l) => l.lessonId == lesson!.lessonId);
        if (currentIdx > 0) {
          final prev = allLessons[currentIdx - 1];
          final completedIds = await ref.read(courseRepositoryProvider).getLessonsStatus(widget.courseId).catchError((_) => <int>[]);
          final isCurrentDone = completedIds.contains(lesson.lessonId);
          final isPrevDone = completedIds.contains(prev.lessonId);
          if (!isCurrentDone && !isPrevDone) {
            isLockedByPrerequisite = true;
            prerequisiteLesson = prev;
          }
        }
      }

      final isUnlocked = (isEnrolled && !isLockedByPrerequisite) || (!isEnrolled && lesson?.isFree == true);

      LessonNavigation? nav;
      LessonProgress? progress;
      List<LessonMaterial> materials = [];
      QuizModel? quiz;

      if (isUnlocked) {
        nav = await lessonRepo.getLessonNavigation(widget.lessonId).catchError((_) => LessonNavigation());
        if (isEnrolled) {
          progress = await lessonRepo.getLessonProgress(widget.lessonId).catchError((_) => LessonProgress(lessonId: widget.lessonId));
        } else {
          progress = LessonProgress(lessonId: widget.lessonId);
        }
        materials = await lessonRepo.getLessonMaterials(widget.lessonId).catchError((_) => <LessonMaterial>[]);
        quiz = await quizRepo.getLessonQuiz(widget.lessonId).catchError((_) => null);
      }

      if (mounted) {
        setState(() {
          _course = course;
          _isEnrolled = isEnrolled;
          _lesson = lesson;
          _navigation = nav;
          _progress = progress;
          _materials = materials;
          _quiz = quiz;
          _isLockedByPrerequisite = isLockedByPrerequisite;
          _prerequisiteLesson = prerequisiteLesson;
          _isLoading = false;
        });

        if (isUnlocked && lesson != null) {
          _initVideo(lesson, progress ?? LessonProgress(lessonId: widget.lessonId));
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

  Future<void> _initVideo(LessonModel lesson, LessonProgress progress) async {
    final videoPath = lesson.playableVideoUrl;
    if (videoPath.isEmpty) {
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
          _videoError = null;
        });
      }
      return;
    }

    final resolvedUrl = mediaUrl(videoPath);
    final uri = Uri.tryParse(resolvedUrl);
    if (uri == null) {
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
          _videoError = 'Invalid video URL: $resolvedUrl';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isVideoLoading = true;
        _videoError = null;
      });
    }

    try {
      final controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _videoController?.removeListener(_onVideoPlayerUpdate);
      _videoController?.dispose();
      _videoController = controller;

      // Listen for playback completion
      _videoController!.addListener(_onVideoPlayerUpdate);

      // Auto-resume from last saved position (for enrolled users)
      if (progress.lastPlaybackPositionSeconds > 0) {
        await _videoController!.seekTo(
          Duration(seconds: progress.lastPlaybackPositionSeconds),
        );
      }

      final chewie = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio > 0
            ? _videoController!.value.aspectRatio
            : 16 / 9,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
      );

      _chewieController?.dispose();
      _chewieController = chewie;

      // Save progress every 5 seconds (for authenticated enrolled users only)
      _progressSaveTimer?.cancel();
      _progressSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        final authRepo = ref.read(authRepositoryProvider);
        if (_isEnrolled && authRepo.isAuthenticated && _videoController != null && _videoController!.value.isPlaying) {
          final currentSeconds = _videoController!.value.position.inSeconds;
          ref
              .read(lessonRepositoryProvider)
              .saveLessonProgress(widget.lessonId, currentSeconds)
              .catchError((_) {});
        }
      });

      if (mounted) {
        setState(() {
          _isVideoLoading = false;
          _videoError = null;
        });
      }
    } catch (e) {
      debugPrint('[_initVideo] Failed to load video: $e');
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
          _videoError = 'Unable to stream video. Please verify the media server is running and try again.';
        });
      }
    }
  }

  void _onVideoPlayerUpdate() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    final duration = controller.value.duration;
    final position = controller.value.position;

    // Detect when video reaches completion
    if (duration > Duration.zero && position >= duration) {
      if (!_hasShownCompletionPrompt) {
        _hasShownCompletionPrompt = true;
        _onVideoCompleted();
      }
    }
  }

  void _onVideoCompleted() {
    if (!mounted) return;

    if (_isEnrolled) {
      // For enrolled student, show the completion prompt (which gates on quiz score)
      if (_progress?.isCompleted != true) {
        _showLessonCompletionPrompt();
      }
      return;
    }

    // For unauthorized / unenrolled preview users:
    final next = _getNextLesson();
    final isNextLocked = next == null || !next.isFree;

    if (isNextLocked) {
      // Prompt user that preview is finished and enrollment is required to continue
      _showPreviewCompletedSheet();
    }
  }

  LessonModel? _getNextLesson() {
    if (_course == null) return null;
    final allLessons = _course!.sections.expand((s) => s.lessons).toList();
    final idx = allLessons.indexWhere((l) => l.lessonId == widget.lessonId);
    if (idx >= 0 && idx < allLessons.length - 1) {
      return allLessons[idx + 1];
    }
    return null;
  }

  LessonModel? _getPreviousLesson() {
    if (_course == null) return null;
    final allLessons = _course!.sections.expand((s) => s.lessons).toList();
    final idx = allLessons.indexWhere((l) => l.lessonId == widget.lessonId);
    if (idx > 0) {
      return allLessons[idx - 1];
    }
    return null;
  }

  void _showPreviewCompletedSheet() {
    if (!mounted) return;
    final theme = Theme.of(context);
    final course = _course;
    final isCourseFree = course?.isFree ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preview Completed!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You've completed previewing '${_lesson?.title}'.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  isCourseFree
                      ? 'Enroll in this free course to unlock all remaining lessons, quizzes, and track your progress!'
                      : 'Enroll in the full course to unlock all remaining lessons, quizzes, downloadable resources, and certificates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.hintColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                if (course != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                              const Text('Full Course Access', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(
                                course.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isCourseFree ? 'Free' : Formatters.formatCurrency(course.price),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _handleEnroll();
                    },
                    child: Text(
                      isCourseFree ? 'Enroll for Free' : 'Enroll Now',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.replay, size: 16),
                        label: const Text('Replay'),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _videoController?.seekTo(Duration.zero);
                          _videoController?.play();
                          _hasShownCompletionPrompt = false;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          context.go('/courses/${widget.courseId}');
                        },
                        child: const Text('Back to Course'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPayToUnlockSheet(LessonModel? targetLesson) {
    final theme = Theme.of(context);
    final course = _course;
    final isCourseFree = course?.isFree ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
                  'Unlock Next Lesson',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                if (targetLesson != null)
                  Text(
                    targetLesson.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Text(
                  isCourseFree
                      ? 'This lesson is locked. Enroll in this free course to unlock all lessons, quizzes, and track progress.'
                      : 'This lesson is locked. Enroll in the full course to get instant access to all video lessons, quizzes, and certificates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.hintColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                if (course != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                              const Text('Full Course Access', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(
                                course.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isCourseFree ? 'Free' : Formatters.formatCurrency(course.price),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _handleEnroll();
                    },
                    child: Text(
                      isCourseFree ? 'Enroll for Free' : 'Enroll Now',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleEnroll() async {
    final authRepo = ref.read(authRepositoryProvider);
    if (!authRepo.isAuthenticated) {
      ToastService.showInfo('Please log in to continue.');
      context.push('/login');
      return;
    }

    if (_course == null) {
      context.go('/courses/${widget.courseId}');
      return;
    }

    if (_course!.isFree) {
      try {
        final paymentRepo = ref.read(paymentRepositoryProvider);
        final checkout = await paymentRepo.checkout(_course!.courseId);
        await paymentRepo.confirmPayment(checkout.paymentId);
        ToastService.showSuccess('Enrolled successfully!');
        _disposePlayer();
        _loadLesson();
      } catch (e) {
        ToastService.showError('Enrollment failed: $e');
      }
      return;
    }

    context.go('/courses/${widget.courseId}');
  }

  /// The minimum quiz score (percentage) required to mark a lesson complete.
  static const double _quizPassThreshold = 90.0;

  /// Returns the student's best quiz score percentage for this lesson, or null
  /// if no quiz exists or no attempt has been made.
  Future<double?> _quizBestPercent() async {
    if (_quiz == null) return null;
    try {
      final attempt = await ref
          .read(quizRepositoryProvider)
          .getQuizAttemptMe(_quiz!.quizId);
      return attempt?.percent;
    } catch (_) {
      return null;
    }
  }

  /// Shows a bottom-sheet prompt asking the student to confirm lesson
  /// completion.  If a quiz is attached to this lesson the student must
  /// have scored ≥ 90 % before the "Mark Complete" action is enabled.
  void _showLessonCompletionPrompt() async {
    final authRepo = ref.read(authRepositoryProvider);
    if (!authRepo.isAuthenticated || !_isEnrolled) {
      ToastService.showInfo('Please enroll in the course to save progress.');
      _showPayToUnlockSheet(null);
      return;
    }

    if (_progress?.isCompleted == true) return;

    final theme = Theme.of(context);
    final hasQuiz = _quiz != null;
    double? bestPercent;

    if (hasQuiz) {
      bestPercent = await _quizBestPercent();
    }

    final quizPassed = !hasQuiz || (bestPercent != null && bestPercent >= _quizPassThreshold);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: quizPassed
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    quizPassed
                        ? Icons.check_circle_outline_rounded
                        : Icons.quiz_outlined,
                    size: 40,
                    color: quizPassed ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  quizPassed
                      ? 'Mark Lesson as Complete?'
                      : 'Quiz Required to Complete',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                if (quizPassed) ...[
                  Text(
                    "You've met all the requirements for \"${_lesson?.title}\". "
                    'Would you like to mark this lesson as complete and move on?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.hintColor,
                      height: 1.4,
                    ),
                  ),
                ] else ...[
                  Text(
                    'You need to score at least ${_quizPassThreshold.toStringAsFixed(0)}% on the lesson quiz '
                    'before you can mark this lesson as complete.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.hintColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Current best score badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Best Score',
                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                            ),
                            Text(
                              bestPercent != null
                                  ? '${bestPercent.toStringAsFixed(0)}%'
                                  : 'Not attempted yet',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: bestPercent != null ? Colors.red : theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Required',
                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                            ),
                            Text(
                              '${_quizPassThreshold.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Primary action button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      quizPassed ? Icons.check_circle : Icons.quiz_outlined,
                      size: 18,
                    ),
                    label: Text(
                      quizPassed
                          ? 'Yes, Mark as Complete'
                          : bestPercent != null
                              ? 'Retake Quiz'
                              : 'Take the Quiz',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: quizPassed ? Colors.green : null,
                      foregroundColor: quizPassed ? Colors.white : null,
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      if (quizPassed) {
                        _handleMarkComplete();
                      } else {
                        context.push('/lessons/${widget.lessonId}/quiz');
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Secondary action
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(quizPassed ? 'Not Yet' : 'Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleMarkComplete() async {
    final authRepo = ref.read(authRepositoryProvider);
    if (!authRepo.isAuthenticated || !_isEnrolled) {
      ToastService.showInfo('Please enroll in the course to save progress.');
      _showPayToUnlockSheet(null);
      return;
    }

    setState(() => _isMarkingComplete = true);
    try {
      await ref.read(lessonRepositoryProvider).markLessonComplete(widget.lessonId);
      ref.read(courseProgressRefreshProvider.notifier).state++;
      ToastService.showSuccess('Lesson completed! Great work.');
      if (mounted) {
        setState(() {
          _isMarkingComplete = false;
          _progress = LessonProgress(
            lessonId: widget.lessonId,
            isCompleted: true,
            lastPlaybackPositionSeconds: _videoController?.value.position.inSeconds ?? 0,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(e.toString());
        setState(() => _isMarkingComplete = false);
      }
    }
  }

  Future<void> _downloadMaterial(String fileUrl) async {
    final resolved = mediaUrl(fileUrl);
    final uri = Uri.tryParse(resolved);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ToastService.showError('Unable to download material');
    }
  }

  Widget _buildLockedLessonView(ThemeData theme) {
    final course = _course;
    final isCourseFree = course?.isFree ?? false;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'This Lesson is Locked',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lesson?.title ?? 'Lesson',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isCourseFree
                        ? 'Enroll in this free course to unlock all lessons, track your learning, and earn a certificate.'
                        : 'This lesson is part of "${course?.title ?? 'the course'}". Enroll now to get instant access to all video lessons, quizzes, and certificates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.hintColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (course != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                                const Text('Course', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(
                                  course.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isCourseFree ? 'Free' : Formatters.formatCurrency(course.price),
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
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_open, size: 18),
                      label: Text(
                        isCourseFree ? 'Enroll for Free' : 'Enroll Now',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _handleEnroll,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to Course Details'),
                    onPressed: () => context.go('/courses/${widget.courseId}'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Lesson...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lesson')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ApiAlert(error: _error ?? 'Failed to load lesson', onRetry: _loadLesson),
          ),
        ),
      );
    }

    final lesson = _lesson!;
    final isUnlocked = (_isEnrolled && !_isLockedByPrerequisite) || (!_isEnrolled && lesson.isFree);

    if (_isLockedByPrerequisite && _prerequisiteLesson != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/courses/${widget.courseId}'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_clock_outlined, size: 56, color: Colors.amber),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Lesson Locked',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'You must complete the previous lesson "${_prerequisiteLesson!.title}" before accessing this lesson.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.hintColor, fontSize: 14),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Go to "${_prerequisiteLesson!.title}"'),
                  onPressed: () {
                    context.pushReplacement(
                      '/courses/${widget.courseId}/lessons/${_prerequisiteLesson!.lessonId}',
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.go('/courses/${widget.courseId}'),
                  child: const Text('Back to Course Curriculum'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!isUnlocked) {
      return Scaffold(
        appBar: AppBar(
          title: Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/courses/${widget.courseId}'),
          ),
        ),
        body: _buildLockedLessonView(theme),
      );
    }

    final prevLesson = _getPreviousLesson();
    final nextLesson = _getNextLesson();

    final isPrevUnlocked = _isEnrolled || (prevLesson?.isFree == true);
    final isNextUnlocked = _isEnrolled || (nextLesson?.isFree == true);

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_quiz != null && _isEnrolled)
            TextButton.icon(
              icon: const Icon(Icons.quiz_outlined, size: 18),
              label: const Text('Quiz'),
              onPressed: () => context.push('/lessons/${widget.lessonId}/quiz'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Free preview guest banner
            if (!_isEnrolled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  border: Border(bottom: BorderSide(color: Colors.green.withValues(alpha: 0.3))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 18, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Free Preview Lesson',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                          ),
                          Text(
                            'You are previewing without enrolling. Enroll in the full course to unlock all lessons, quizzes, and track progress.',
                            style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showPayToUnlockSheet(null),
                      child: const Text('Enroll Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Video Player or Placeholder
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: _chewieController != null &&
                        _chewieController!.videoPlayerController.value.isInitialized
                    ? Chewie(controller: _chewieController!)
                    : Center(
                        child: _isVideoLoading
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white70),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Loading video stream...',
                                    style: TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              )
                            : _videoError != null
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error_outline_rounded, size: 40, color: Colors.amberAccent),
                                        const SizedBox(height: 8),
                                        Text(
                                          _videoError!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.colorScheme.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          icon: const Icon(Icons.refresh_rounded, size: 16),
                                          label: const Text('Retry Video'),
                                          onPressed: () {
                                            if (_lesson != null) {
                                              _initVideo(_lesson!, _progress ?? LessonProgress(lessonId: widget.lessonId));
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_circle_fill, size: 48, color: Colors.white54),
                                      const SizedBox(height: 8),
                                      Text(
                                        lesson.playableVideoUrl.isNotEmpty
                                            ? 'Loading video...'
                                            : 'No video stream available for this lesson',
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_isEnrolled)
                        ElevatedButton.icon(
                          icon: Icon(
                            _progress?.isCompleted == true
                                ? Icons.check_circle
                                : Icons.check,
                            size: 16,
                            color: _progress?.isCompleted == true ? Colors.green : null,
                          ),
                          label: Text(_progress?.isCompleted == true ? 'Completed' : 'Mark Complete'),
                          onPressed: _isMarkingComplete || _progress?.isCompleted == true
                              ? null
                              : _showLessonCompletionPrompt,
                        )
                      else
                        InkWell(
                          onTap: () {
                            ToastService.showInfo('Enroll in the course to track progress and mark lessons complete.');
                            _showPayToUnlockSheet(null);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.remove_red_eye, size: 14, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'Free Trial Video',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (lesson.duration != null)
                    Text(
                      'Duration: ${lesson.duration}',
                      style: TextStyle(color: theme.hintColor, fontSize: 12),
                    ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Previous'),
                        onPressed: prevLesson != null && isPrevUnlocked
                            ? () {
                                context.pushReplacement(
                                  '/courses/${widget.courseId}/lessons/${prevLesson.lessonId}',
                                );
                              }
                            : null,
                      ),

                      // Next Lesson Button:
                      // If user is enrolled: navigates if next lesson exists
                      // If user is guest/unenrolled:
                      //   - If next lesson is free: navigates to preview
                      //   - If next lesson is locked: shows locked button and opens paywall dialog!
                      if (_isEnrolled)
                        ElevatedButton.icon(
                          icon: Icon(
                            _progress?.isCompleted == true ? Icons.arrow_forward : Icons.lock_outline,
                            size: 16,
                          ),
                          label: Text(
                            nextLesson == null
                                ? 'Next Lesson'
                                : _progress?.isCompleted == true
                                    ? 'Next Lesson'
                                    : 'Next Lesson (Locked)',
                          ),
                          style: _progress?.isCompleted != true && nextLesson != null
                              ? ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                                )
                              : null,
                          onPressed: nextLesson == null
                              ? null
                              : _progress?.isCompleted == true
                                  ? () {
                                      context.pushReplacement(
                                        '/courses/${widget.courseId}/lessons/${nextLesson.lessonId}',
                                      );
                                    }
                                  : () {
                                      ToastService.showInfo(
                                        'Please complete this lesson before proceeding. If this lesson has a quiz, you need to score at least 90%.',
                                      );
                                    },
                        )
                      else if (nextLesson == null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('Next Lesson'),
                          onPressed: null,
                        )
                      else if (nextLesson.isFree)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('Next Preview'),
                          onPressed: () {
                            context.pushReplacement(
                              '/courses/${widget.courseId}/lessons/${nextLesson.lessonId}',
                            );
                          },
                        )
                      else
                        ElevatedButton.icon(
                          icon: const Icon(Icons.lock_outline, size: 16),
                          label: const Text('Next Lesson (Locked)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => _showPayToUnlockSheet(nextLesson),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Lesson Notes
                  if (lesson.textContent != null && lesson.textContent!.isNotEmpty) ...[
                    const Text(
                      'Lesson Notes & Resources',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lesson.textContent!,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Lesson Materials
                  if (_materials.isNotEmpty) ...[
                    const Text(
                      'Downloadable Materials',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ..._materials.map((mat) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.attach_file, color: Colors.blue),
                            title: Text(mat.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: mat.fileType != null ? Text(mat.fileType!, style: const TextStyle(fontSize: 11)) : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.download, size: 20),
                              onPressed: mat.fileUrl != null ? () => _downloadMaterial(mat.fileUrl!) : null,
                            ),
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],

                  // Quiz Banner if available
                  if (_quiz != null && _isEnrolled) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.quiz, color: Colors.amber, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_quiz!.quizTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('Test your knowledge • ${_quiz!.totalPoint} points', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => context.push('/lessons/${widget.lessonId}/quiz'),
                            child: const Text('Take Quiz'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
