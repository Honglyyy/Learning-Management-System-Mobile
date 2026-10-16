import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_flutter/features/instructor_studio/screens/instructor_studio_screen.dart';
import 'package:lms_flutter/features/instructor_studio/widgets/instructor_analytic_tab.dart';
import 'package:lms_flutter/features/instructor_studio/widgets/instructor_home_tab.dart';
import 'package:lms_flutter/features/instructor_studio/widgets/instructor_manage_tab.dart';
import 'package:lms_flutter/core/providers.dart';
import 'package:lms_flutter/features/home/screens/home_screen.dart';
import 'package:lms_flutter/models/course_model.dart';
import 'package:lms_flutter/models/dashboard_models.dart';
import 'package:lms_flutter/models/enrollment_model.dart';
import 'package:lms_flutter/models/instructor_model.dart';
import 'package:lms_flutter/models/payment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('InstructorHomeTab renders greeting, balance card, and lists all courses', (tester) async {
    final dashboard = InstructorDashboardDTO(
      totalCourses: 2,
      totalStudents: 120,
      averageRating: 4.8,
      grossRevenue: 248.75,
    );
    final profile = InstructorModel(
      id: 1,
      fullName: 'Lay Hongly',
    );
    final courses = [
      CourseModel(
        courseId: 101,
        title: 'Flutter Masterclass 2026',
        description: 'Complete cross platform app development',
        price: 49.99,
        level: 'Intermediate',
        status: 'PUBLISHED',
        enrollmentCount: 75,
        rating: 4.9,
        lessonCount: 24,
      ),
      CourseModel(
        courseId: 102,
        title: 'Backend with Spring Boot',
        description: 'Enterprise REST APIs and Microservices',
        price: 0,
        level: 'Advanced',
        status: 'DRAFT',
        enrollmentCount: 45,
        rating: 4.7,
        lessonCount: 18,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InstructorHomeTab(
            dashboard: dashboard,
            instructorProfile: profile,
            courses: courses,
            recentPayments: const [],
            onSearchTap: () {},
            onNavigateTab: (_) {},
            onOpenCourseCreate: () {},
            onRefresh: () {},
          ),
        ),
      ),
    );

    // Verify greeting and name
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Lay Hongly'), findsWidgets);

    // Verify balance card
    expect(find.text('Current Balance'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('248.75'), findsOneWidget);

    // Verify courses listing section
    expect(find.text('All Courses'), findsOneWidget);
    expect(find.text('Create New Course'), findsOneWidget);
    expect(find.text('Flutter Masterclass 2026'), findsOneWidget);
    expect(find.text('Backend with Spring Boot'), findsOneWidget);
    expect(find.text('75 students'), findsOneWidget);
    expect(find.text('45 students'), findsOneWidget);
  });

  testWidgets('InstructorAnalyticTab renders amount of students, pie chart distribution, and average rating', (tester) async {
    final dashboard = InstructorDashboardDTO(
      totalCourses: 2,
      totalStudents: 120,
      averageRating: 4.8,
      grossRevenue: 248.57,
    );
    final courses = [
      CourseModel(
        courseId: 101,
        title: 'Flutter Masterclass',
        description: 'Flutter course',
        enrollmentCount: 75,
        rating: 4.8,
      ),
      CourseModel(
        courseId: 102,
        title: 'Spring Boot APIs',
        description: 'Java course',
        enrollmentCount: 45,
        rating: 4.9,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InstructorAnalyticTab(
            dashboard: dashboard,
            enrollmentReport: EnrollmentReportDTO(),
            quizReport: QuizReportDTO(),
            courses: courses,
            onBackTap: () {},
            onRefresh: () {},
          ),
        ),
      ),
    );

    // Verify analytics top bar and student amounts
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('120'), findsWidgets);
    expect(find.text('Total Enrolled Students'), findsOneWidget);

    // Verify average rating and courses metrics
    expect(find.text('★ 4.8'), findsOneWidget);
    expect(find.text('Avg Rating'), findsOneWidget);
    expect(find.text('Students Enrolled Per Course'), findsOneWidget);
  });

  testWidgets('InstructorManageTab renders course & materials studio and hubs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InstructorManageTab(
            courses: const [],
            assignments: const [],
            submissions: const [],
            selectedAssignmentId: null,
            onSelectAssignment: (_) {},
            onOpenGrading: (_) {},
            enrolledStudents: const [],
            quizReport: null,
            onOpenCourseCreate: () {},
            onCourseMutated: () {},
            onBackTap: () {},
            onRefresh: () {},
          ),
        ),
      ),
    );

    // Verify Manage Studio Header
    expect(find.text('Manage Studio'), findsOneWidget);
    expect(find.text('New Course'), findsOneWidget);

    // Verify Hub items for Course & Materials management
    expect(find.text('Courses & Materials'), findsOneWidget);
    expect(find.text('Grading & Submissions'), findsOneWidget);
    expect(find.text('Enrolled Students'), findsOneWidget);
    expect(find.text('Quizzes & Tests'), findsOneWidget);

    // Verify Studio Health rings
    expect(find.text('Studio Health & Progress'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Graded'), findsOneWidget);
  });

  testWidgets('InstructorStudioScreen bottom navigation contains Home, Analytic, Manage, Profile and renders HomeScreen on Tab 0', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: InstructorStudioScreen(),
        ),
      ),
    );

    // Verify all 4 tabs in bottom navigation
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Analytic'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Let async data loading complete
    await tester.pumpAndSettle();

    // Verify Tab 0 mounts HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('InstructorManageTab renders enrolled students in a DataTable with class dropdown filter and search', (tester) async {
    final courses = [
      CourseModel(
        courseId: 201,
        title: 'Flutter Mobile App Development',
        description: 'Flutter mobile course description',
        enrollmentCount: 2,
      ),
      CourseModel(
        courseId: 202,
        title: 'Spring Boot Microservices',
        description: 'Spring boot course description',
        enrollmentCount: 1,
      ),
    ];

    final enrolledStudents = [
      EnrollmentModel(
        enrollmentId: 1,
        userId: 10,
        userName: 'Alice Smith',
        userEmail: 'alice@example.com',
        courseId: 201,
        courseTitle: 'Flutter Mobile App Development',
        status: 'ACTIVE',
        progressPercent: 75.0,
      ),
      EnrollmentModel(
        enrollmentId: 2,
        userId: 11,
        userName: 'Bob Johnson',
        userEmail: 'bob@example.com',
        courseId: 201,
        courseTitle: 'Flutter Mobile App Development',
        status: 'COMPLETED',
        progressPercent: 100.0,
      ),
      EnrollmentModel(
        enrollmentId: 3,
        userId: 12,
        userName: 'Charlie Brown',
        userEmail: 'charlie@example.com',
        courseId: 202,
        courseTitle: 'Spring Boot Microservices',
        status: 'ACTIVE',
        progressPercent: 30.0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InstructorManageTab(
            courses: courses,
            assignments: const [],
            submissions: const [],
            selectedAssignmentId: null,
            onSelectAssignment: (_) {},
            onOpenGrading: (_) {},
            enrolledStudents: enrolledStudents,
            quizReport: null,
            onOpenCourseCreate: () {},
            onCourseMutated: () {},
            onBackTap: () {},
            onRefresh: () {},
            initialActiveTab: ManageStudioTab.students,
          ),
        ),
      ),
    );

    // Verify filter card & class dropdown
    expect(find.text('Filter by Class / Course'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int?>), findsOneWidget);

    // Verify table headers
    expect(find.text('Student Name'), findsOneWidget);
    expect(find.text('Class / Course'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);

    // Verify DataTable rows
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('Bob Johnson'), findsOneWidget);
    expect(find.text('Charlie Brown'), findsOneWidget);

    // Verify search functionality
    await tester.enterText(find.byKey(const Key('enrolled_students_search_field')), 'Alice');
    await tester.pumpAndSettle();

    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('Bob Johnson'), findsNothing);
    expect(find.text('Charlie Brown'), findsNothing);

    // Clear search filter
    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('Bob Johnson'), findsOneWidget);
    expect(find.text('Charlie Brown'), findsOneWidget);
  });
}
