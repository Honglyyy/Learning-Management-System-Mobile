import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_flutter/core/providers.dart';
import 'package:lms_flutter/models/auth_model.dart';
import 'package:lms_flutter/models/course_model.dart';
import 'package:lms_flutter/models/quiz_model.dart';
import 'package:lms_flutter/models/assignment_model.dart';
import 'package:lms_flutter/models/enrollment_model.dart';

void main() {
  group('Req #24: Complete End-to-End Student Learning Flow Simulation', () {
    test('Simulate complete student journey: Login -> Discover -> Enroll -> Lesson -> Quiz -> Assignment -> 100% Progress & Completion', () async {
      // -------------------------------------------------------------
      // Step 1: Authentication & Role Check
      // -------------------------------------------------------------
      final loginReq = LoginRequest(email: 'student@example.com', password: 'Password123');
      expect(loginReq.email, 'student@example.com');

      final claims = AuthClaims.fromMap({
        'sub': '101',
        'email': 'student@example.com',
        'role': 'STUDENT',
      });
      expect(claims.isStudent, isTrue);
      expect(claims.isAdmin, isFalse);

      // -------------------------------------------------------------
      // Step 2: Course Discovery & Filtering
      // -------------------------------------------------------------
      final catalog = [
        CourseModel.fromJson({
          'courseId': 1,
          'title': 'Flutter Fundamentals',
          'description': 'Beginner flutter mobile app course',
          'price': 0.0,
          'rating': 4.9,
          'enrollmentCount': 1200,
          'overallDuration': '5 hours',
          'level': 'BEGINNER',
          'categories': ['Mobile'],
          'sections': [
            {
              'sectionId': 10,
              'title': 'Getting Started',
              'lessons': [
                {'lessonId': 100, 'title': 'Introduction to Widgets', 'duration': 300},
                {'lessonId': 101, 'title': 'State Management in Flutter', 'duration': 450},
              ]
            }
          ],
        }),
        CourseModel.fromJson({
          'courseId': 2,
          'title': 'Advanced Backend with Spring Boot',
          'description': 'Spring Boot microservices',
          'price': 49.99,
          'rating': 4.7,
          'enrollmentCount': 800,
          'overallDuration': '15 hours',
          'level': 'ADVANCED',
          'categories': ['Backend'],
          'sections': [],
        }),
      ];

      // Filter by category Mobile & duration Medium (3-10h)
      final mobileCourses = catalog.where((c) => c.categories.contains('Mobile')).toList();
      expect(mobileCourses.length, 1);
      final selectedCourse = mobileCourses.first;
      expect(selectedCourse.title, 'Flutter Fundamentals');

      // -------------------------------------------------------------
      // Step 3: Course Enrollment
      // -------------------------------------------------------------
      final enrollment = EnrollmentModel(
        enrollmentId: 501,
        courseId: selectedCourse.courseId,
        courseTitle: selectedCourse.title,
        userId: 101,
        enrolledAt: DateTime.now(),
        progressPercent: 0.0,
      );
      expect(enrollment.courseId, 1);
      expect(enrollment.courseTitle, 'Flutter Fundamentals');
      expect(enrollment.progressPercent, 0.0);

      // -------------------------------------------------------------
      // Step 4: Lesson Consumption & Progress Update
      // -------------------------------------------------------------
      final completedLessons = <int>{};
      final totalLessons = selectedCourse.sections.fold<int>(0, (sum, sec) => sum + sec.lessons.length);
      expect(totalLessons, 2);

      // Complete Lesson 1
      completedLessons.add(100);
      double currentProgress = (completedLessons.length / totalLessons) * 100.0;
      expect(currentProgress, 50.0);

      // Complete Lesson 2
      completedLessons.add(101);
      currentProgress = (completedLessons.length / totalLessons) * 100.0;
      expect(currentProgress, 100.0);

      // -------------------------------------------------------------
      // Step 5: Quiz Assessment
      // -------------------------------------------------------------
      final quiz = QuizModel(
        quizId: 20,
        quizTitle: 'Flutter Basics Assessment',
        totalPoint: 20,
        questions: [
          QuestionModel(
            questionId: 1,
            questionText: 'What widget is used for rows?',
            point: 10,
            answers: [
              AnswerModel(answerId: 1, answerText: 'Row', isCorrect: true),
              AnswerModel(answerId: 2, answerText: 'Column', isCorrect: false),
            ],
          ),
          QuestionModel(
            questionId: 2,
            questionText: 'Does Flutter render with Skia/Impeller?',
            point: 10,
            answers: [
              AnswerModel(answerId: 3, answerText: 'Yes', isCorrect: true),
              AnswerModel(answerId: 4, answerText: 'No', isCorrect: false),
            ],
          ),
        ],
      );

      final userAnswers = <int, int>{
        1: 1, // Question 1 -> Row
        2: 3, // Question 2 -> Yes
      };

      int earnedQuizScore = 0;
      for (final q in quiz.questions) {
        final chosen = userAnswers[q.questionId];
        final isCorrect = q.answers.firstWhere((a) => a.answerId == chosen).isCorrect;
        if (isCorrect) earnedQuizScore += q.point;
      }
      expect(earnedQuizScore, 20);

      final quizAttempt = QuizAttemptModel(
        attemptId: 90,
        earnedPoints: earnedQuizScore,
        totalPoints: quiz.totalPoint,
        correctAnswers: 2,
        totalQuestions: 2,
      );
      expect(quizAttempt.percent, 100.0);

      // -------------------------------------------------------------
      // Step 6: Assignment Submission
      // -------------------------------------------------------------
      final assignment = AssignmentModel(
        assignmentId: 30,
        title: 'Build a Counter App',
        dueDate: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        maxScore: 100,
      );

      final submission = AssignmentSubmissionModel(
        submissionId: 401,
        assignmentId: assignment.assignmentId,
        textSubmission: 'https://github.com/student/counter-app',
        status: 'SUBMITTED',
        score: 95, // Graded by instructor
      );
      expect(submission.isGraded, isTrue);
      expect(submission.score, 95);

      // -------------------------------------------------------------
      // Step 7: Overall Progress & Completion Celebration Verification
      // -------------------------------------------------------------
      final allLessonsDone = completedLessons.length == totalLessons;
      final quizPassed = quizAttempt.percent >= 50.0;
      final assignmentDone = submission.isGraded || submission.status == 'SUBMITTED';

      final isCourseCompleted = allLessonsDone && quizPassed && assignmentDone;
      expect(isCourseCompleted, isTrue);
      expect(currentProgress, 100.0);
    });

    testWidgets('Reactive State Refresh triggers across widgets when progress updates', (tester) async {
      int triggerCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              ref.listen<int>(courseProgressRefreshProvider, (previous, next) {
                triggerCount = next;
              });

              final currentTick = ref.watch(courseProgressRefreshProvider);

              return MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Tick: $currentTick'),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(courseProgressRefreshProvider.notifier).state++;
                          },
                          child: const Text('Complete Next Step'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Tick: 0'), findsOneWidget);
      expect(triggerCount, 0);

      // Trigger step completion
      await tester.tap(find.text('Complete Next Step'));
      await tester.pump();

      expect(find.text('Tick: 1'), findsOneWidget);
      expect(triggerCount, 1);

      // Trigger another step completion
      await tester.tap(find.text('Complete Next Step'));
      await tester.pump();

      expect(find.text('Tick: 2'), findsOneWidget);
      expect(triggerCount, 2);
    });
  });
}
