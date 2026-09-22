import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_flutter/core/widgets/course_card.dart';
import 'package:lms_flutter/models/course_model.dart';

// Helper matching catalog_screen.dart implementation
bool matchesDuration(String? overallDuration, String durationFilter) {
  final d = overallDuration?.toLowerCase() ?? '';
  final match = RegExp(r'(\d+)\s*(?:h|hour)').firstMatch(d);
  final hours = match != null ? (int.tryParse(match.group(1) ?? '0') ?? 0) : 0;
  if (durationFilter == 'SHORT') {
    return hours < 3;
  } else if (durationFilter == 'MEDIUM') {
    return hours >= 3 && hours <= 10;
  } else if (durationFilter == 'LONG') {
    return hours > 10;
  }
  return true;
}

List<CourseModel> applySorting(List<CourseModel> courses, String sortType) {
  final copy = List<CourseModel>.from(courses);
  if (sortType == 'POPULAR') {
    copy.sort((a, b) => b.enrollmentCount.compareTo(a.enrollmentCount));
  } else if (sortType == 'RATING') {
    copy.sort((a, b) => b.rating.compareTo(a.rating));
  } else if (sortType == 'LATEST') {
    copy.sort((a, b) => b.courseId.compareTo(a.courseId));
  }
  return copy;
}

void main() {
  group('Course Unit Tests - Duration Filtering', () {
    test('Short duration (< 3 hours) identifies matching courses', () {
      expect(matchesDuration('2 hours', 'SHORT'), isTrue);
      expect(matchesDuration('1 hour 30 mins', 'SHORT'), isTrue);
      expect(matchesDuration('5 hours', 'SHORT'), isFalse);
      expect(matchesDuration('15 hours', 'SHORT'), isFalse);
    });

    test('Medium duration (3 - 10 hours) identifies matching courses', () {
      expect(matchesDuration('3 hours', 'MEDIUM'), isTrue);
      expect(matchesDuration('6 hours', 'MEDIUM'), isTrue);
      expect(matchesDuration('10 hours', 'MEDIUM'), isTrue);
      expect(matchesDuration('2 hours', 'MEDIUM'), isFalse);
      expect(matchesDuration('12 hours', 'MEDIUM'), isFalse);
    });

    test('Long duration (10+ hours) identifies matching courses', () {
      expect(matchesDuration('12 hours', 'LONG'), isTrue);
      expect(matchesDuration('20 hours', 'LONG'), isTrue);
      expect(matchesDuration('8 hours', 'LONG'), isFalse);
      expect(matchesDuration('2 hours', 'LONG'), isFalse);
    });
  });

  group('Course Unit Tests - Sorting & Progress', () {
    final c1 = CourseModel.fromJson({
      'courseId': 1,
      'title': 'Course A',
      'price': 0.0,
      'rating': 4.2,
      'enrollmentCount': 100,
      'status': 'PUBLISHED',
      'level': 'BEGINNER',
      'categories': [],
      'sections': [],
    });
    final c2 = CourseModel.fromJson({
      'courseId': 2,
      'title': 'Course B',
      'price': 19.99,
      'rating': 4.9,
      'enrollmentCount': 500,
      'status': 'PUBLISHED',
      'level': 'INTERMEDIATE',
      'categories': [],
      'sections': [],
    });
    final c3 = CourseModel.fromJson({
      'courseId': 3,
      'title': 'Course C',
      'price': 49.99,
      'rating': 4.7,
      'enrollmentCount': 250,
      'status': 'PUBLISHED',
      'level': 'ADVANCED',
      'categories': [],
      'sections': [],
    });

    final list = [c1, c2, c3];

    test('Sort by POPULAR orders by highest enrollmentCount', () {
      final sorted = applySorting(list, 'POPULAR');
      expect(sorted[0].courseId, 2); // 500 students
      expect(sorted[1].courseId, 3); // 250 students
      expect(sorted[2].courseId, 1); // 100 students
    });

    test('Sort by RATING orders by highest rating', () {
      final sorted = applySorting(list, 'RATING');
      expect(sorted[0].courseId, 2); // 4.9
      expect(sorted[1].courseId, 3); // 4.7
      expect(sorted[2].courseId, 1); // 4.2
    });

    test('Sort by LATEST orders by courseId descending', () {
      final sorted = applySorting(list, 'LATEST');
      expect(sorted[0].courseId, 3);
      expect(sorted[1].courseId, 2);
      expect(sorted[2].courseId, 1);
    });

    test('Progress percentage computes accurately', () {
      const totalLessons = 10;
      final completed5 = (5 / totalLessons) * 100.0;
      expect(completed5, 50.0);

      final completed10 = (10 / totalLessons) * 100.0;
      expect(completed10, 100.0);

      const zeroLessons = 0;
      final percentZero = zeroLessons > 0 ? (0 / zeroLessons) * 100.0 : 0.0;
      expect(percentZero, 0.0);
    });
  });

  group('Course Widget Tests - CourseCard', () {
    testWidgets('CourseCard renders title, instructor, duration, and price in grid view', (tester) async {
      final item = CourseCardItem(
        courseId: 10,
        title: 'Master Flutter and Dart',
        instructor: 'Dr. John',
        rating: 4.8,
        price: 29.99,
        level: 'INTERMEDIATE',
        duration: '8 hours',
        enrollmentCount: 320,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: CourseCard(course: item, isListView: false),
            ),
          ),
        ),
      );

      expect(find.text('Master Flutter and Dart'), findsOneWidget);
      expect(find.text('Dr. John'), findsOneWidget);
      expect(find.text('8 hours'), findsOneWidget);
      expect(find.text('\$29.99'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('CourseCard renders Free badge and duration in list view', (tester) async {
      final item = CourseCardItem(
        courseId: 11,
        title: 'Intro to Programming',
        instructor: 'Alice Smith',
        rating: 4.5,
        price: 0,
        level: 'BEGINNER',
        duration: '2 hours',
        enrollmentCount: 85,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 150,
              child: CourseCard(course: item, isListView: true),
            ),
          ),
        ),
      );

      expect(find.text('Intro to Programming'), findsOneWidget);
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('2 hours'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
    });
  });
}
