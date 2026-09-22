import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_flutter/core/api/api_client.dart';
import 'package:lms_flutter/core/providers.dart';
import 'package:lms_flutter/features/assignments/screens/student_assignment_screen.dart';
import 'package:lms_flutter/models/assignment_model.dart';
import 'package:lms_flutter/repositories/assignment_repository.dart';

// Helper matching status resolution logic in StudentAssignmentScreen
String resolveAssignmentStatus({
  AssignmentSubmissionModel? submission,
  DateTime? dueDate,
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  if (submission != null) {
    if (submission.isGraded) return 'Graded';
    if (submission.status == 'REVIEWED') return 'Reviewed';
    if (submission.status == 'LATE') return 'Late Submission';
    if (submission.status == 'SUBMITTED') return 'Submitted';
  } else if (dueDate != null) {
    if (dueDate.isBefore(currentTime)) return 'Overdue / Missing';
  }
  return 'Not Submitted';
}

class FakeAssignmentRepository implements AssignmentRepository {
  final AssignmentSubmissionModel? submissionToReturn;

  FakeAssignmentRepository({this.submissionToReturn});

  @override
  Future<AssignmentSubmissionModel?> getSubmissionMe(int assignmentId) async {
    return submissionToReturn;
  }

  @override
  Future<void> submitAssignment(
    int assignmentId, {
    String? textSubmission,
    String? fileUrl,
    String? filePublicId,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeApiClient implements ApiClient {
  final Map<String, dynamic> assignmentJson;

  FakeApiClient(this.assignmentJson);

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return assignmentJson;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Assignment Unit Tests - Status Determination', () {
    final now = DateTime(2026, 9, 14, 12, 0);

    test('Submission with score is marked Graded', () {
      final sub = AssignmentSubmissionModel(
        submissionId: 1,
        status: 'GRADED',
        score: 95,
      );
      expect(resolveAssignmentStatus(submission: sub, now: now), 'Graded');

      // Even if status string is SUBMITTED, having a score means it's graded
      final subWithScore = AssignmentSubmissionModel(
        submissionId: 2,
        status: 'SUBMITTED',
        score: 80,
      );
      expect(resolveAssignmentStatus(submission: subWithScore, now: now), 'Graded');
    });

    test('Submission with status LATE is marked Late Submission', () {
      final sub = AssignmentSubmissionModel(
        submissionId: 3,
        status: 'LATE',
      );
      expect(resolveAssignmentStatus(submission: sub, now: now), 'Late Submission');
    });

    test('Submission with status SUBMITTED is marked Submitted', () {
      final sub = AssignmentSubmissionModel(
        submissionId: 4,
        status: 'SUBMITTED',
      );
      expect(resolveAssignmentStatus(submission: sub, now: now), 'Submitted');
    });

    test('Overdue assignment without submission is marked Overdue / Missing', () {
      final pastDue = DateTime(2026, 9, 1, 12, 0);
      expect(resolveAssignmentStatus(submission: null, dueDate: pastDue, now: now), 'Overdue / Missing');
    });

    test('Future assignment without submission is marked Not Submitted', () {
      final futureDue = DateTime(2026, 10, 1, 12, 0);
      expect(resolveAssignmentStatus(submission: null, dueDate: futureDue, now: now), 'Not Submitted');
    });
  });

  group('Assignment Unit Tests - Model Serialization', () {
    test('AssignmentModel serializes and deserializes dates and fields', () {
      final model = AssignmentModel(
        assignmentId: 55,
        title: 'Mobile App Architecture',
        description: 'Implement clean code principles',
        startDate: '2026-09-01T00:00:00Z',
        dueDate: '2026-09-30T23:59:59Z',
        maxScore: 100,
      );

      final json = model.toJson();
      expect(json['assignmentId'], 55);
      expect(json['title'], 'Mobile App Architecture');
      expect(json['maxScore'], 100);
      expect(json['startDate'], '2026-09-01T00:00:00Z');
      expect(json['dueDate'], '2026-09-30T23:59:59Z');

      final fromJson = AssignmentModel.fromJson(json);
      expect(fromJson.assignmentId, 55);
      expect(fromJson.title, 'Mobile App Architecture');
      expect(fromJson.maxScore, 100);
    });

    test('Assignment score percentage evaluates accurately', () {
      const maxScore = 50;
      const earnedScore = 45;
      final percentage = (earnedScore / maxScore) * 100.0;
      expect(percentage, 90.0);
    });
  });

  group('Assignment Widget Tests - StudentAssignmentScreen UI', () {
    final mockAssignmentJson = {
      'assignmentId': 77,
      'title': 'Build Riverpod State Flow',
      'description': 'Create reactive state providers and listen to changes.',
      'instructions': 'Submit your GitHub repo URL or write-up below.',
      'startDate': '2026-09-10T08:00:00.000Z',
      'dueDate': '2026-09-25T23:59:59.000Z',
      'maxScore': 100,
    };

    testWidgets('StudentAssignmentScreen renders assignment details and status badge', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeApiClient = FakeApiClient(mockAssignmentJson);
      final fakeAssignRepo = FakeAssignmentRepository(
        submissionToReturn: AssignmentSubmissionModel(
          submissionId: 10,
          assignmentId: 77,
          textSubmission: 'Here is my GitHub repository link.',
          status: 'SUBMITTED',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApiClient),
            assignmentRepositoryProvider.overrideWithValue(fakeAssignRepo),
          ],
          child: const MaterialApp(
            home: StudentAssignmentScreen(assignmentId: 77),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify assignment title and description
      expect(find.text('Build Riverpod State Flow'), findsAtLeastNWidgets(1));
      expect(find.text('Create reactive state providers and listen to changes.'), findsOneWidget);

      // Verify max points and status badge
      expect(find.text('Max Score: 100 pts'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);

      // Verify submission field contains previously submitted text
      expect(find.text('Here is my GitHub repository link.'), findsOneWidget);
    });
  });
}
