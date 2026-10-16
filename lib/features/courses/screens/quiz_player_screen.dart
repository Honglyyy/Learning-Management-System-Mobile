import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/quiz_model.dart';

class QuizPlayerScreen extends ConsumerStatefulWidget {
  final int lessonId;

  const QuizPlayerScreen({super.key, required this.lessonId});

  @override
  ConsumerState<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends ConsumerState<QuizPlayerScreen> {
  QuizModel? _quiz;
  QuizAttemptModel? _previousAttempt;
  QuizAttemptModel? _latestResult;

  // Question ID -> Selected Answer ID
  final Map<int, int> _selectedAnswers = {};
  int _currentQuestionIndex = 0;
  bool _showAllQuestionsMode = false;

  // Timer
  Timer? _timer;
  int _remainingSeconds = 600; // 10 minutes default time limit

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = 600;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        if (_latestResult == null && !_isSubmitting) {
          ToastService.showWarning('Time is up! Submitting your answers automatically.');
          _handleSubmitQuiz(autoSubmit: true);
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final quizRepo = ref.read(quizRepositoryProvider);
      final quiz = await quizRepo.getLessonQuiz(widget.lessonId);

      QuizAttemptModel? attempt;
      if (quiz != null) {
        attempt = await quizRepo.getQuizAttemptMe(quiz.quizId).catchError((_) => null);
      }

      if (mounted) {
        setState(() {
          _quiz = quiz;
          _previousAttempt = attempt;
          _isLoading = false;
        });

        if (_latestResult == null && quiz != null && quiz.questions.isNotEmpty) {
          _startTimer();
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

  Future<void> _handleSubmitQuiz({bool autoSubmit = false}) async {
    if (_quiz == null) return;

    if (!autoSubmit && _selectedAnswers.length < _quiz!.questions.length) {
      ToastService.showWarning('Please answer all questions before submitting.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final quizRepo = ref.read(quizRepositoryProvider);
      final result = await quizRepo.submitQuiz(
        _quiz!.quizId,
        _selectedAnswers.values.toList(),
      );

      _stopTimer();
      // Trigger reactive state refresh across all screens
      ref.read(courseProgressRefreshProvider.notifier).state++;

      final updatedQuiz = await quizRepo.getLessonQuiz(widget.lessonId).catchError((_) => null);

      ToastService.showSuccess('Quiz submitted! You scored ${result.earnedPoints}/${result.totalPoints}');
      if (mounted) {
        setState(() {
          if (updatedQuiz != null) _quiz = updatedQuiz;
          _latestResult = result;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  void _retakeQuiz() {
    setState(() {
      _latestResult = null;
      _selectedAnswers.clear();
      _currentQuestionIndex = 0;
      _showAllQuestionsMode = false;
    });
    _startTimer();
  }

  Widget _buildTimerBadge() {
    if (_latestResult != null) return const SizedBox.shrink();

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final isUrgent = _remainingSeconds < 60;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? Colors.red : Colors.orange,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: isUrgent ? Colors.red : Colors.orange),
          const SizedBox(width: 4),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isUrgent ? Colors.red : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(QuizAttemptModel result) {
    final theme = Theme.of(context);
    final percent = result.percent;
    final isPassed = percent >= 70.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      color: isPassed
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.red.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isPassed ? Colors.green : Colors.red),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isPassed ? Icons.check_circle_outline : Icons.highlight_off,
              color: isPassed ? Colors.green : Colors.red,
              size: 48,
            ),
            const SizedBox(height: 10),
            Text(
              isPassed ? 'Congratulations! You Passed!' : 'Quiz Completed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPassed ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Score: ${result.earnedPoints} / ${result.totalPoints} points (${percent.toStringAsFixed(0)}%)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Correct Answers: ${result.correctAnswers} / ${result.totalQuestions}',
              style: TextStyle(color: theme.hintColor, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Retake Quiz'),
              onPressed: _retakeQuiz,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepSelector(QuizModel quiz, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${quiz.questions.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              TextButton.icon(
                icon: Icon(_showAllQuestionsMode ? Icons.view_carousel : Icons.list, size: 16),
                label: Text(_showAllQuestionsMode ? 'Step-by-Step Mode' : 'View All List'),
                onPressed: () => setState(() => _showAllQuestionsMode = !_showAllQuestionsMode),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: quiz.questions.asMap().entries.map((entry) {
                final idx = entry.key;
                final q = entry.value;
                final isAnswered = _selectedAnswers.containsKey(q.questionId);
                final isCurrent = idx == _currentQuestionIndex;

                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() {
                      _currentQuestionIndex = idx;
                      _showAllQuestionsMode = false;
                    }),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : isAnswered
                                ? Colors.green.withValues(alpha: 0.15)
                                : theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : isAnswered
                                  ? Colors.green
                                  : theme.dividerColor,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isCurrent
                                ? Colors.white
                                : isAnswered
                                    ? Colors.green
                                    : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleQuestionCard(QuestionModel question, int qIndex, ThemeData theme) {
    final selectedAnswerId = _selectedAnswers[question.questionId];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Q${qIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.questionText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, height: 1.3),
                  ),
                ),
                Text(
                  '${question.point} pts',
                  style: TextStyle(color: theme.hintColor, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RadioGroup<int>(
              groupValue: selectedAnswerId,
              onChanged: (val) {
                if (_latestResult != null || val == null) return;
                setState(() {
                  _selectedAnswers[question.questionId] = val;
                });
              },
              child: Column(
                children: question.answers.map((answer) {
                  final isSelected = selectedAnswerId == answer.answerId;

                  Color? tileBg;
                  if (_latestResult != null) {
                    if (answer.isCorrect) {
                      tileBg = Colors.green.withValues(alpha: 0.15);
                    } else if (isSelected && !answer.isCorrect) {
                      tileBg = Colors.red.withValues(alpha: 0.15);
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: tileBg ?? (isSelected ? theme.colorScheme.primary.withValues(alpha: 0.05) : null),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: RadioListTile<int>(
                        dense: true,
                        title: Text(answer.answerText, style: const TextStyle(fontSize: 14)),
                        value: answer.answerId,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepNavigationControls(QuizModel quiz) {
    final isFirst = _currentQuestionIndex == 0;
    final isLast = _currentQuestionIndex == quiz.questions.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Previous'),
          onPressed: isFirst
              ? null
              : () => setState(() => _currentQuestionIndex--),
        ),
        if (!isLast)
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Next Question'),
            onPressed: () => setState(() => _currentQuestionIndex++),
          )
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 16),
            label: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit Quiz'),
            onPressed: _isSubmitting ? null : () => _handleSubmitQuiz(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _quiz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ApiAlert(
              error: _error ?? 'No quiz available for this lesson.',
              onRetry: _loadQuiz,
            ),
          ),
        ),
      );
    }

    final quiz = _quiz!;

    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.quizTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          _buildTimerBadge(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quiz Header Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.quizTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total: ${quiz.totalPoint} pts • ${quiz.questions.length} questions • 10 mins limit',
                        style: TextStyle(color: theme.hintColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ApiAlert(error: _error),

            // Results Card or Best Score Banner & Quiz History
            if (_latestResult != null)
              _buildResultCard(_latestResult!)
            else if (_previousAttempt != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history_edu, size: 22, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Quiz Attempt History',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Best: ${_previousAttempt!.percent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Previous Score: ${_previousAttempt!.earnedPoints}/${_previousAttempt!.totalPoints} pts',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _previousAttempt!.percent >= 70 ? 'PASSED' : 'FAILED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _previousAttempt!.percent >= 70 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            if (quiz.questions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48.0),
                  child: Column(
                    children: [
                      Icon(Icons.quiz_outlined, size: 54, color: theme.disabledColor),
                      const SizedBox(height: 12),
                      Text(
                        'This quiz does not have any questions yet.',
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              )
            else if (_latestResult != null || _showAllQuestionsMode) ...[
              // Review Mode (All questions visible after submit or when user toggles view all)
              _buildStepSelector(quiz, theme),
              ...quiz.questions.asMap().entries.map((entry) {
                return _buildSingleQuestionCard(entry.value, entry.key, theme);
              }),
              if (_latestResult == null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _handleSubmitQuiz(),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Quiz', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ] else ...[
              // Step-by-Step Single Question Mode
              _buildStepSelector(quiz, theme),
              _buildSingleQuestionCard(
                quiz.questions[_currentQuestionIndex],
                _currentQuestionIndex,
                theme,
              ),
              const SizedBox(height: 12),
              _buildStepNavigationControls(quiz),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
