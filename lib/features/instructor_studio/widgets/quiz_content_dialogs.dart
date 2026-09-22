import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/lesson_model.dart';
import '../../../models/quiz_model.dart';

// ---------------------------------------------------------------------------
// Quiz Edit Dialog
// ---------------------------------------------------------------------------

class QuizEditDialog extends ConsumerStatefulWidget {
  final QuizModel? quiz;
  final List<LessonModel> lessons;
  final VoidCallback onSaved;

  const QuizEditDialog({
    super.key,
    this.quiz,
    required this.lessons,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    QuizModel? quiz,
    required List<LessonModel> lessons,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuizEditDialog(
        quiz: quiz,
        lessons: lessons,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<QuizEditDialog> createState() => _QuizEditDialogState();
}

class _QuizEditDialogState extends ConsumerState<QuizEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _pointsCtrl;
  int? _selectedLessonId;
  bool _isSaving = false;

  bool get isEditMode => widget.quiz != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.quiz?.title ?? '');
    _pointsCtrl = TextEditingController(
      text: (widget.quiz?.totalPoints ?? 10).toString(),
    );
    _selectedLessonId = widget.quiz?.lessonId;
    if (_selectedLessonId == null && widget.lessons.isNotEmpty) {
      _selectedLessonId = widget.lessons.first.lessonId;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLessonId == null) {
      ToastService.showError('Please select a lesson');
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'title': _titleCtrl.text.trim(),
      'totalPoints': int.tryParse(_pointsCtrl.text.trim()) ?? 10,
      'lessonId': _selectedLessonId,
    };

    try {
      final quizRepo = ref.read(quizRepositoryProvider);
      if (isEditMode) {
        await quizRepo.updateQuiz(widget.quiz!.quizId, payload);
        ToastService.showSuccess('Quiz updated');
      } else {
        await quizRepo.createQuiz(payload);
        ToastService.showSuccess('Quiz created');
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ToastService.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditMode ? 'Edit Quiz' : 'Create Quiz'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Quiz title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pointsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Points *',
                  hintText: '10',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Points is required';
                  final numVal = int.tryParse(v.trim());
                  if (numVal == null || numVal < 0) return 'Invalid points';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _selectedLessonId,
                decoration: const InputDecoration(
                  labelText: 'Lesson *',
                  border: OutlineInputBorder(),
                ),
                items: widget.lessons.map((l) {
                  return DropdownMenuItem<int>(
                    value: l.lessonId,
                    child: Text(
                      l.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedLessonId = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveQuiz,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditMode ? 'Save Changes' : 'Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Question Edit Dialog
// ---------------------------------------------------------------------------

class QuestionEditDialog extends ConsumerStatefulWidget {
  final QuestionModel? question;
  final List<QuizModel> quizzes;
  final VoidCallback onSaved;

  const QuestionEditDialog({
    super.key,
    this.question,
    required this.quizzes,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    QuestionModel? question,
    required List<QuizModel> quizzes,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuestionEditDialog(
        question: question,
        quizzes: quizzes,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<QuestionEditDialog> createState() => _QuestionEditDialogState();
}

class _QuestionEditDialogState extends ConsumerState<QuestionEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionTextCtrl;
  late final TextEditingController _pointCtrl;
  int? _selectedQuizId;
  bool _isSaving = false;

  bool get isEditMode => widget.question != null;

  @override
  void initState() {
    super.initState();
    _questionTextCtrl = TextEditingController(
      text: widget.question?.questionText ?? '',
    );
    _pointCtrl = TextEditingController(
      text: widget.question?.point != null ? widget.question!.point.toString() : '',
    );
    _selectedQuizId = widget.question?.quizId;
    if (_selectedQuizId == null && widget.quizzes.isNotEmpty) {
      _selectedQuizId = widget.quizzes.first.quizId;
    }
  }

  @override
  void dispose() {
    _questionTextCtrl.dispose();
    _pointCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQuizId == null) {
      ToastService.showError('Please select a quiz');
      return;
    }

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'questionText': _questionTextCtrl.text.trim(),
      'quizId': _selectedQuizId,
    };
    if (_pointCtrl.text.trim().isNotEmpty) {
      payload['point'] = int.tryParse(_pointCtrl.text.trim());
    }

    try {
      final quizRepo = ref.read(quizRepositoryProvider);
      if (isEditMode) {
        await quizRepo.updateQuestion(widget.question!.questionId, payload);
        ToastService.showSuccess('Question updated');
      } else {
        await quizRepo.createQuestion(payload);
        ToastService.showSuccess('Question created');
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ToastService.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditMode ? 'Edit Question' : 'Create Question'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _questionTextCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Question *',
                  hintText: 'Enter question text...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Question text is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pointCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Points',
                  hintText: 'Auto split if empty',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _selectedQuizId,
                decoration: const InputDecoration(
                  labelText: 'Quiz *',
                  border: OutlineInputBorder(),
                ),
                items: widget.quizzes.map((q) {
                  return DropdownMenuItem<int>(
                    value: q.quizId,
                    child: Text(
                      q.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedQuizId = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveQuestion,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditMode ? 'Save Changes' : 'Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Answer Edit Dialog
// ---------------------------------------------------------------------------

class AnswerEditDialog extends ConsumerStatefulWidget {
  final AnswerModel? answer;
  final List<QuestionModel> questions;
  final VoidCallback onSaved;

  const AnswerEditDialog({
    super.key,
    this.answer,
    required this.questions,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    AnswerModel? answer,
    required List<QuestionModel> questions,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnswerEditDialog(
        answer: answer,
        questions: questions,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<AnswerEditDialog> createState() => _AnswerEditDialogState();
}

class _AnswerEditDialogState extends ConsumerState<AnswerEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _answerTextCtrl;
  int? _selectedQuestionId;
  late bool _isCorrect;
  bool _isSaving = false;

  bool get isEditMode => widget.answer != null;

  @override
  void initState() {
    super.initState();
    _answerTextCtrl = TextEditingController(
      text: widget.answer?.answerText ?? '',
    );
    _isCorrect = widget.answer?.isCorrect ?? false;
    _selectedQuestionId = widget.answer?.questionId;
    if (_selectedQuestionId == null && widget.questions.isNotEmpty) {
      _selectedQuestionId = widget.questions.first.questionId;
    }
  }

  @override
  void dispose() {
    _answerTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAnswer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQuestionId == null) {
      ToastService.showError('Please select a question');
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'answerText': _answerTextCtrl.text.trim(),
      'isCorrect': _isCorrect,
      'questionId': _selectedQuestionId,
    };

    try {
      final quizRepo = ref.read(quizRepositoryProvider);
      if (isEditMode) {
        await quizRepo.updateAnswer(widget.answer!.answerId, payload);
        ToastService.showSuccess('Answer updated');
      } else {
        await quizRepo.createAnswer(payload);
        ToastService.showSuccess('Answer created');
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ToastService.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditMode ? 'Edit Answer' : 'Create Answer'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _answerTextCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Answer *',
                  hintText: 'Enter answer text...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Answer text is required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _selectedQuestionId,
                decoration: const InputDecoration(
                  labelText: 'Question *',
                  border: OutlineInputBorder(),
                ),
                items: widget.questions.map((q) {
                  return DropdownMenuItem<int>(
                    value: q.questionId,
                    child: Text(
                      q.questionText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedQuestionId = v),
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                value: _isCorrect,
                onChanged: (v) => setState(() => _isCorrect = v ?? false),
                title: const Text('Correct Answer'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveAnswer,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditMode ? 'Save Changes' : 'Save'),
        ),
      ],
    );
  }
}
