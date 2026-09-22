import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_flutter/core/providers.dart';
import 'package:lms_flutter/features/courses/screens/quiz_player_screen.dart';
import 'package:lms_flutter/models/quiz_model.dart';
import 'package:lms_flutter/repositories/quiz_repository.dart';

// Helper matching timer formatting in QuizPlayerScreen
String formatQuizTimer(int totalSeconds) {
  final min = totalSeconds ~/ 60;
  final sec = totalSeconds % 60;
  return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

class FakeQuizRepository implements QuizRepository {
  final QuizModel? quizToReturn;
  final QuizAttemptModel? attemptToReturn;

  FakeQuizRepository({this.quizToReturn, this.attemptToReturn});

  @override
  Future<QuizModel?> getLessonQuiz(int lessonId) async {
    return quizToReturn;
  }

  @override
  Future<QuizAttemptModel?> getQuizAttemptMe(int quizId) async {
    return attemptToReturn;
  }

  @override
  Future<QuizAttemptModel> submitQuiz(int quizId, List<int> answerIds) async {
    return attemptToReturn ??
        QuizAttemptModel(
          attemptId: 1,
          earnedPoints: 20,
          totalPoints: 20,
          correctAnswers: 2,
          totalQuestions: 2,
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Quiz Unit Tests - Timer & Navigation Logic', () {
    test('Timer format string outputs correct MM:SS representation', () {
      expect(formatQuizTimer(600), '10:00');
      expect(formatQuizTimer(599), '09:59');
      expect(formatQuizTimer(75), '01:15');
      expect(formatQuizTimer(9), '00:09');
      expect(formatQuizTimer(0), '00:00');
    });

    test('Quiz navigation bounds prevent out-of-range navigation', () {
      const totalQuestions = 3;
      int currentIndex = 0;

      // At start: cannot go previous
      expect(currentIndex > 0, isFalse);
      expect(currentIndex < totalQuestions - 1, isTrue);

      // Move next
      currentIndex++;
      expect(currentIndex, 1);
      expect(currentIndex > 0, isTrue);
      expect(currentIndex < totalQuestions - 1, isTrue);

      // Move next to end
      currentIndex++;
      expect(currentIndex, 2);
      expect(currentIndex > 0, isTrue);
      expect(currentIndex < totalQuestions - 1, isFalse); // cannot go next beyond last question
    });

    test('Question answer completion tracking counts answered questions', () {
      final selectedAnswers = <int, int>{};
      expect(selectedAnswers.length, 0);

      // Answer question 101 with answer 501
      selectedAnswers[101] = 501;
      expect(selectedAnswers.containsKey(101), isTrue);
      expect(selectedAnswers.containsKey(102), isFalse);
      expect(selectedAnswers.length, 1);

      // Answer question 102 with answer 503
      selectedAnswers[102] = 503;
      expect(selectedAnswers.length, 2);
    });

    test('Quiz scoring evaluates percentage and result accurately', () {
      final attemptPassed = QuizAttemptModel(
        attemptId: 1,
        earnedPoints: 80,
        totalPoints: 100,
        correctAnswers: 8,
        totalQuestions: 10,
      );
      expect(attemptPassed.earnedPoints, 80);
      expect(attemptPassed.percent, 80.0);

      final attemptFailed = QuizAttemptModel(
        attemptId: 2,
        earnedPoints: 40,
        totalPoints: 100,
        correctAnswers: 4,
        totalQuestions: 10,
      );
      expect(attemptFailed.earnedPoints, 40);
      expect(attemptFailed.percent, 40.0);
    });
  });

  group('Quiz Widget Tests - Quiz Player UI', () {
    final mockQuiz = QuizModel(
      quizId: 99,
      quizTitle: 'Flutter Architecture Quiz',
      totalPoint: 20,
      questions: [
        QuestionModel(
          questionId: 1,
          questionText: 'What widget is used for immutable layout?',
          point: 10,
          answers: [
            AnswerModel(answerId: 11, answerText: 'StatelessWidget', isCorrect: true),
            AnswerModel(answerId: 12, answerText: 'StatefulWidget', isCorrect: false),
          ],
        ),
        QuestionModel(
          questionId: 2,
          questionText: 'Which package is used for reactive state?',
          point: 10,
          answers: [
            AnswerModel(answerId: 21, answerText: 'Riverpod', isCorrect: true),
            AnswerModel(answerId: 22, answerText: 'UnmanagedState', isCorrect: false),
          ],
        ),
      ],
    );

    testWidgets('QuizPlayerScreen renders questions, step chips, and navigation buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakeQuizRepository(quizToReturn: mockQuiz);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quizRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: QuizPlayerScreen(lessonId: 1),
          ),
        ),
      );

      // Pump to finish _loadQuiz
      await tester.pumpAndSettle();

      // Verify quiz title
      expect(find.text('Flutter Architecture Quiz'), findsAtLeastNWidgets(1));

      // Verify question 1 is active
      expect(find.text('What widget is used for immutable layout?'), findsOneWidget);
      expect(find.text('StatelessWidget'), findsOneWidget);
      expect(find.text('StatefulWidget'), findsOneWidget);

      // Verify step indicators: numbers 1, 2 exist and active question has Q1 badge
      expect(find.text('Q1'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Tap on an answer choice
      await tester.tap(find.text('StatelessWidget'));
      await tester.pumpAndSettle();

      // Navigate to Next Question
      final nextButton = find.widgetWithText(ElevatedButton, 'Next Question');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Verify Question 2 is now shown
      expect(find.text('Which package is used for reactive state?'), findsOneWidget);
      expect(find.text('Riverpod'), findsOneWidget);

      // Navigate back with Previous
      final prevButton = find.widgetWithText(OutlinedButton, 'Previous');
      expect(prevButton, findsOneWidget);
      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      // Verify back on Question 1
      expect(find.text('What widget is used for immutable layout?'), findsOneWidget);
    });
  });
}
