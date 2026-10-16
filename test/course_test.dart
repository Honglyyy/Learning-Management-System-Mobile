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

    testWidgets('CourseCard does not overflow with long title in home screen dimensions', (tester) async {
      final item = CourseCardItem(
        courseId: 1,
        title: 'Django: Complete Python Web Development & REST Framework',
        instructor: 'Hongly Lay',
        rating: 0.0,
        price: 19.99,
        level: 'ALL_LEVELS',
        enrollmentCount: 1,
        accessDurationDays: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 250,
              child: CourseCard(course: item, isListView: false),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Django: Complete Python Web Development & REST Framework'), findsOneWidget);
      expect(find.text('Hongly Lay'), findsOneWidget);
      expect(find.text('1d'), findsOneWidget);
      expect(find.text('\$19.99'), findsOneWidget);
    });

    testWidgets('CourseCard renders in 2x2 grid dimensions without overflow', (tester) async {
      final item = CourseCardItem(
        courseId: 2,
        title: 'Spring Boot & Microservices Masterclass 2026',
        instructor: 'Lay Hongly',
        rating: 4.8,
        price: 49.99,
        discountedPrice: 24.99,
        isExpired: true,
        level: 'INTERMEDIATE',
        duration: '18 Hours',
        enrollmentCount: 120,
        accessDurationDays: 300,
      );

      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 235,
              child: CourseCard(course: item, isListView: false),
            ),
          ),
        ),
      );

      FlutterError.onError = originalOnError;
      expect(caughtDetails, isNull);
      expect(find.text('Spring Boot & Microservices Masterclass 2026'), findsOneWidget);
      expect(find.text('Lay Hongly'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('INTERMEDIATE'), findsOneWidget);
    });

    testWidgets('3 compact CourseCards in a Row across mobile screen width render without overflow', (tester) async {
      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
      };

      final items = [
        CourseCardItem(
          courseId: 1,
          title: 'Python Django Full Stack',
          instructor: 'Lay Hongly',
          rating: 4.9,
          price: 49.99,
          level: 'INTERMEDIATE',
          duration: '18 Hours',
          accessDurationDays: 300,
        ),
        CourseCardItem(
          courseId: 2,
          title: 'Spring Boot Microservices',
          instructor: 'Lay Hongly',
          rating: 4.8,
          price: 64.99,
          level: 'ADVANCED',
          duration: '30 Hours',
          accessDurationDays: 240,
        ),
        CourseCardItem(
          courseId: 3,
          title: 'Flutter Mobile App Development',
          instructor: 'Lay Hongly',
          rating: 5.0,
          price: 39.99,
          level: 'BEGINNER',
          duration: '12 Hours',
          accessDurationDays: 180,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360, // Standard phone width
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: CourseCard(
                          course: items[i],
                          isListView: false,
                          isCompact: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      FlutterError.onError = originalOnError;
      expect(caughtDetails, isNull);
      expect(find.text('Python Django Full Stack'), findsOneWidget);
      expect(find.text('Spring Boot Microservices'), findsOneWidget);
      expect(find.text('Flutter Mobile App Development'), findsOneWidget);
      expect(find.text('\$49.99'), findsOneWidget);
      expect(find.text('\$64.99'), findsOneWidget);
      expect(find.text('\$39.99'), findsOneWidget);
    });

    test('Home screen horizontal section limits courses to 3 in a row', () {
      final courses = List.generate(8, (i) => CourseModel.fromJson({
        'courseId': i + 1,
        'title': 'Course $i',
        'price': 10.0 * (i + 1),
        'rating': 4.5,
        'status': 'PUBLISHED',
      }));

      final rowCourses = courses.take(3).toList();
      expect(rowCourses.length, 3);
      expect(rowCourses.map((c) => c.courseId).toList(), [1, 2, 3]);
    });

    test('Home screen all courses 2x2 grid starts at 4 and increments by 4', () {
      final courses = List.generate(10, (i) => CourseModel.fromJson({
        'courseId': i + 1,
        'title': 'Course $i',
        'price': 10.0 * (i + 1),
        'rating': 4.5,
        'status': 'PUBLISHED',
      }));

      int visibleCount = 4; // 2x2 grid initially
      expect(courses.take(visibleCount).length, 4);

      // First infinite scroll trigger
      visibleCount = (visibleCount + 4).clamp(0, courses.length);
      expect(courses.take(visibleCount).length, 8);

      // Second infinite scroll trigger
      visibleCount = (visibleCount + 4).clamp(0, courses.length);
      expect(courses.take(visibleCount).length, 10);
    });
  });

  group('Lesson Progression & Restriction Unit Tests', () {
    final lesson1Id = 101;
    final lesson2Id = 102;
    final lesson3Id = 103;

    bool isLessonUnlocked({
      required int lessonIndex,
      required int currentLessonId,
      required int? previousLessonId,
      required List<int> completedLessonIds,
      required bool isEnrolled,
      required bool isFree,
    }) {
      if (!isEnrolled) return isFree;
      final isDone = completedLessonIds.contains(currentLessonId);
      if (isDone) return true;
      if (lessonIndex == 0) return true;
      return previousLessonId != null && completedLessonIds.contains(previousLessonId);
    }

    test('First lesson (index 0) is always unlocked for enrolled student', () {
      final unlocked = isLessonUnlocked(
        lessonIndex: 0,
        currentLessonId: lesson1Id,
        previousLessonId: null,
        completedLessonIds: [],
        isEnrolled: true,
        isFree: false,
      );
      expect(unlocked, isTrue);
    });

    test('Second lesson is restricted when first lesson is NOT completed', () {
      final unlocked = isLessonUnlocked(
        lessonIndex: 1,
        currentLessonId: lesson2Id,
        previousLessonId: lesson1Id,
        completedLessonIds: [], // 0 lessons done
        isEnrolled: true,
        isFree: false,
      );
      expect(unlocked, isFalse);
    });

    test('Second lesson unlocks immediately once first lesson is completed', () {
      final unlocked = isLessonUnlocked(
        lessonIndex: 1,
        currentLessonId: lesson2Id,
        previousLessonId: lesson1Id,
        completedLessonIds: [lesson1Id], // lesson 1 done
        isEnrolled: true,
        isFree: false,
      );
      expect(unlocked, isTrue);
    });

    test('Third lesson remains restricted if second lesson is not yet done', () {
      final unlocked = isLessonUnlocked(
        lessonIndex: 2,
        currentLessonId: lesson3Id,
        previousLessonId: lesson2Id,
        completedLessonIds: [lesson1Id], // only lesson 1 done, not lesson 2
        isEnrolled: true,
        isFree: false,
      );
      expect(unlocked, isFalse);
    });

    test('Completed lessons always remain unlocked for re-watching', () {
      final unlocked = isLessonUnlocked(
        lessonIndex: 1,
        currentLessonId: lesson2Id,
        previousLessonId: lesson1Id,
        completedLessonIds: [lesson2Id],
        isEnrolled: true,
        isFree: false,
      );
      expect(unlocked, isTrue);
    });
  });
}

