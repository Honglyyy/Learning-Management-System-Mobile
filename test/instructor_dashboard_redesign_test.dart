import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_flutter/features/instructor_studio/screens/instructor_studio_screen.dart';
import 'package:lms_flutter/features/instructor_studio/widgets/assignment_form_dialog.dart';
import 'package:lms_flutter/features/instructor_studio/widgets/instructor_analytic_tab.dart';
import 'package:lms_flutter/features/instructor_studio/widgets/instructor_home_tab.dart';
import 'package:lms_flutter/features/instructor_studio/widgets/instructor_manage_tab.dart';
import 'package:lms_flutter/core/providers.dart';
import 'package:lms_flutter/features/home/screens/home_screen.dart';
import 'package:lms_flutter/models/assignment_model.dart';
import 'package:lms_flutter/models/category_model.dart';
import 'package:lms_flutter/models/course_model.dart';
import 'package:lms_flutter/models/dashboard_models.dart';
import 'package:lms_flutter/models/enrollment_model.dart';
import 'package:lms_flutter/models/instructor_model.dart';
import 'package:lms_flutter/models/section_model.dart';
import 'package:lms_flutter/repositories/assignment_repository.dart';
import 'package:lms_flutter/repositories/category_repository.dart';
import 'package:lms_flutter/repositories/course_repository.dart';
import 'package:lms_flutter/repositories/dashboard_repository.dart';
import 'package:lms_flutter/repositories/enrollment_repository.dart';
import 'package:lms_flutter/repositories/instructor_repository.dart';
import 'package:lms_flutter/repositories/section_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<InstructorDashboardDTO> getInstructorDashboard() async =>
      InstructorDashboardDTO(totalCourses: 2, totalStudents: 10);

  @override
  Future<EnrollmentReportDTO> getEnrollmentReports() async => EnrollmentReportDTO();

  @override
  Future<QuizReportDTO> getQuizReports() async => QuizReportDTO();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCourseRepository implements CourseRepository {
  final List<CourseModel> instructorCourses;
  _FakeCourseRepository(this.instructorCourses);

  @override
  Future<List<CourseModel>> getInstructorCoursesMe() async => instructorCourses;

  @override
  Future<List<CourseModel>> getFeatured() async => const [];

  @override
  Future<List<CourseModel>> getPopular() async => const [];

  @override
  Future<List<CourseModel>> getCourses({
    String? query,
    int? categoryId,
    String? level,
    double? minRating,
    String? sort,
  }) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getCategories() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEnrollmentRepository implements EnrollmentRepository {
  @override
  Future<List<EnrollmentModel>> getAllEnrollments({int? courseId}) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeInstructorRepository implements InstructorRepository {
  @override
  Future<InstructorModel> getMyProfile() async =>
      InstructorModel(id: 1, fullName: 'Instructor Test');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSectionRepository implements SectionRepository {
  final Map<int, List<SectionModel>> sectionsByCourse;
  _FakeSectionRepository(this.sectionsByCourse);

  @override
  Future<List<SectionModel>> getInstructorSections({int? courseId}) async {
    if (courseId == null) return const [];
    return sectionsByCourse[courseId] ?? const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStudioAssignmentRepository implements AssignmentRepository {
  final Map<int, List<AssignmentModel>> assignmentsByCourse;
  final Map<int, List<AssignmentSubmissionModel>> submissionsByAssignment;
  bool getAssignmentsCalled = false;
  int? gradedSubmissionId;
  num? gradedScore;
  String? gradedGrade;
  String? gradedFeedback;
  Map<String, dynamic>? createdBody;
  int? updatedId;
  Map<String, dynamic>? updatedBody;

  _FakeStudioAssignmentRepository({
    required this.assignmentsByCourse,
    required this.submissionsByAssignment,
  });

  @override
  Future<List<AssignmentModel>> getAssignments() async {
    getAssignmentsCalled = true;
    throw UnimplementedError('GET /api/assignments does not exist on backend');
  }

  @override
  Future<List<AssignmentModel>> getCourseAssignments(int courseId) async {
    return assignmentsByCourse[courseId] ?? const [];
  }

  @override
  Future<List<AssignmentSubmissionModel>> getSubmissions(int assignmentId) async {
    return submissionsByAssignment[assignmentId] ?? const [];
  }

  @override
  Future<void> gradeSubmission(
    int submissionId, {
    num? score,
    String? grade,
    String? feedback,
  }) async {
    gradedSubmissionId = submissionId;
    gradedScore = score;
    gradedGrade = grade;
    gradedFeedback = feedback;
  }

  @override
  Future<void> createAssignment(Map<String, dynamic> body) async {
    createdBody = body;
  }

  @override
  Future<void> updateAssignment(int id, Map<String, dynamic> body) async {
    updatedId = id;
    updatedBody = body;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
    expect(find.text('****   ****   ****   1474'), findsNothing);
    expect(find.text('Ex. Date'), findsNothing);
    expect(find.text('10/28'), findsNothing);

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

  test('AssignmentModel and AssignmentSubmissionModel handle double numbers and optional fields', () {
    final assignJson = {
      'assignmentId': 12.0,
      'courseId': 3.0,
      'courseTitle': 'Spring Boot APIs',
      'sectionId': 7.0,
      'sectionTitle': 'Week 1',
      'title': 'Build REST Controller',
      'maxScore': 100.0,
      'supportingFileUrl': '/uploads/spec.pdf',
      'supportingFilePublicId': 'lms/spec',
      'allowResubmission': false,
    };
    final assign = AssignmentModel.fromJson(assignJson);
    expect(assign.assignmentId, 12);
    expect(assign.courseId, 3);
    expect(assign.sectionId, 7);
    expect(assign.sectionTitle, 'Week 1');
    expect(assign.maxScore, 100);
    expect(assign.supportingFilePublicId, 'lms/spec');
    expect(assign.allowResubmission, isFalse);

    final subJson = {
      'submissionId': 44.0,
      'assignmentId': 12.0,
      'studentId': 99.0,
      'studentName': 'Jane Doe',
      'studentEmail': 'jane@example.com',
      'textSubmission': 'https://github.com/jane/lms',
      'fileUrl': '/uploads/work.zip',
      'status': 'SUBMITTED',
      'score': 88.5,
      'grade': 'B',
      'feedback': 'Well structured',
    };
    final sub = AssignmentSubmissionModel.fromJson(subJson);
    expect(sub.submissionId, 44);
    expect(sub.assignmentId, 12);
    expect(sub.studentId, 99);
    expect(sub.score, 88.5);
    expect(sub.isGraded, isTrue);
  });

  testWidgets('InstructorManageTab filters submissions by status and exposes assignment actions', (tester) async {
    int? createCourseArg;
    bool createCalled = false;
    AssignmentModel? editedAssignment;
    AssignmentModel? deletedAssignment;

    final courses = [
      CourseModel(courseId: 10, title: 'Flutter Fundamentals', description: 'Mobile'),
      CourseModel(courseId: 20, title: 'Spring Boot Backend', description: 'API'),
    ];
    final assignments = [
      AssignmentModel(
        assignmentId: 101,
        courseId: 10,
        courseTitle: 'Flutter Fundamentals',
        sectionTitle: 'State Management',
        title: 'Riverpod Homework',
        description: 'Build a counter provider',
        maxScore: 50,
      ),
      AssignmentModel(
        assignmentId: 202,
        courseId: 20,
        courseTitle: 'Spring Boot Backend',
        title: 'JPA Entities',
        maxScore: 100,
      ),
    ];
    final submissions = [
      AssignmentSubmissionModel(
        submissionId: 1,
        assignmentId: 101,
        assignmentTitle: 'Riverpod Homework',
        studentName: 'Alice Student',
        studentEmail: 'alice@example.com',
        textSubmission: 'My Riverpod solution',
        fileUrl: '/uploads/riverpod.pdf',
        status: 'SUBMITTED',
      ),
      AssignmentSubmissionModel(
        submissionId: 2,
        assignmentId: 202,
        assignmentTitle: 'JPA Entities',
        studentName: 'Bob Student',
        studentEmail: 'bob@example.com',
        textSubmission: 'Entity mapping solution',
        status: 'GRADED',
        score: 95,
        grade: 'A',
        feedback: 'Clean relations',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InstructorManageTab(
            courses: courses,
            assignments: assignments,
            submissions: submissions,
            selectedAssignmentId: 101,
            onSelectAssignment: (_) {},
            onOpenGrading: (_) {},
            onCreateAssignment: (cid) {
              createCalled = true;
              createCourseArg = cid;
            },
            onEditAssignment: (a) => editedAssignment = a,
            onDeleteAssignment: (a) => deletedAssignment = a,
            enrolledStudents: const [],
            quizReport: null,
            onOpenCourseCreate: () {},
            onCourseMutated: () {},
            onBackTap: () {},
            onRefresh: () {},
            initialActiveTab: ManageStudioTab.assignments,
          ),
        ),
      ),
    );

    // Selected assignment card and New Assignment button should appear
    expect(find.text('New Assignment'), findsOneWidget);
    expect(find.text('Max 50 pts'), findsOneWidget);
    expect(find.text('My Riverpod solution'), findsOneWidget);
    expect(find.text('Attached Submission File'), findsOneWidget);
    expect(find.text('Alice Student'), findsOneWidget);

    // Filter chips scoped to selected assignment 101 (1 total, 1 pending, 0 graded)
    expect(find.text('All (1)'), findsOneWidget);
    expect(find.text('Pending (1)'), findsOneWidget);
    expect(find.text('Graded (0)'), findsOneWidget);

    // Tap New Assignment button
    await tester.ensureVisible(find.text('New Assignment'));
    await tester.tap(find.text('New Assignment'));
    await tester.pump();
    expect(createCalled, isTrue);
    expect(createCourseArg, isNull);

    // Tap Edit and Delete on selected assignment card
    await tester.ensureVisible(find.byTooltip('Edit Assignment'));
    await tester.tap(find.byTooltip('Edit Assignment'));
    await tester.pump();
    expect(editedAssignment?.assignmentId, 101);

    await tester.ensureVisible(find.byTooltip('Delete Assignment'));
    await tester.tap(find.byTooltip('Delete Assignment'));
    await tester.pump();
    expect(deletedAssignment?.assignmentId, 101);
  });

  testWidgets('InstructorManageTab filters submissions by Pending and Graded status chips', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final courses = [
      CourseModel(courseId: 10, title: 'Flutter Fundamentals', description: 'Mobile'),
    ];
    final assignments = [
      AssignmentModel(
        assignmentId: 101,
        courseId: 10,
        courseTitle: 'Flutter Fundamentals',
        title: 'Riverpod Homework',
        maxScore: 100,
      ),
    ];
    final submissions = [
      AssignmentSubmissionModel(
        submissionId: 1,
        assignmentId: 101,
        assignmentTitle: 'Riverpod Homework',
        studentName: 'Pending Student',
        status: 'SUBMITTED',
      ),
      AssignmentSubmissionModel(
        submissionId: 2,
        assignmentId: 101,
        assignmentTitle: 'Riverpod Homework',
        studentName: 'Graded Student',
        status: 'GRADED',
        score: 95,
        grade: 'A',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InstructorManageTab(
            courses: courses,
            assignments: assignments,
            submissions: submissions,
            selectedAssignmentId: null,
            onSelectAssignment: (_) {},
            onOpenGrading: (_) {},
            enrolledStudents: const [],
            quizReport: null,
            onOpenCourseCreate: () {},
            onCourseMutated: () {},
            onBackTap: () {},
            onRefresh: () {},
            initialActiveTab: ManageStudioTab.assignments,
          ),
        ),
      ),
    );

    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Pending (1)'), findsOneWidget);
    expect(find.text('Graded (1)'), findsOneWidget);
    expect(find.text('Pending Student'), findsOneWidget);
    expect(find.text('Graded Student'), findsOneWidget);

    await tester.tap(find.text('Pending (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Pending Student'), findsOneWidget);
    expect(find.text('Graded Student'), findsNothing);

    await tester.tap(find.text('Graded (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Pending Student'), findsNothing);
    expect(find.text('Graded Student'), findsOneWidget);
  });

  testWidgets('AssignmentFormDialog loads course sections and creates an assignment', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeAssignRepo = _FakeStudioAssignmentRepository(
      assignmentsByCourse: const {},
      submissionsByAssignment: const {},
    );
    final fakeSectionRepo = _FakeSectionRepository({
      10: [
        SectionModel(sectionId: 5, title: 'Week 1: Setup', courseId: 10),
      ],
    });
    bool savedCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(fakeAssignRepo),
          sectionRepositoryProvider.overrideWithValue(fakeSectionRepo),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  AssignmentFormDialog.show(
                    ctx,
                    courses: [
                      CourseModel(courseId: 10, title: 'Course 10', description: 'Desc'),
                    ],
                    onSaved: () => savedCalled = true,
                  );
                },
                child: const Text('Open Form'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Form'));
    await tester.pumpAndSettle();

    expect(find.text('Create Assignment'), findsAtLeastNWidgets(1));
    expect(find.text('Course Section (Optional)'), findsOneWidget);

    // Fill required Title field
    final titleField = find.widgetWithText(TextFormField, 'Title *');
    await tester.enterText(titleField, 'Middleware Task');

    await tester.tap(find.text('Create Assignment').last);
    await tester.pumpAndSettle();

    expect(savedCalled, isTrue);
    expect(fakeAssignRepo.createdBody?['courseId'], 10);
    expect(fakeAssignRepo.createdBody?['title'], 'Middleware Task');
    expect(fakeAssignRepo.createdBody?['maxScore'], 100.0);
  });

  testWidgets('InstructorStudioScreen fetches assignments per course, renders student submissions, and submits grades', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final fakeAssignRepo = _FakeStudioAssignmentRepository(
      assignmentsByCourse: {
        10: [
          AssignmentModel(
            assignmentId: 101,
            courseId: 10,
            courseTitle: 'Course 1',
            title: 'Empty Assignment',
            maxScore: 100,
          ),
        ],
        20: [
          AssignmentModel(
            assignmentId: 202,
            courseId: 20,
            courseTitle: 'Course 2',
            title: 'Build REST API',
            maxScore: 100,
          ),
        ],
      },
      submissionsByAssignment: {
        101: const [],
        202: [
          AssignmentSubmissionModel(
            submissionId: 501,
            assignmentId: 202,
            assignmentTitle: 'Build REST API',
            studentId: 7,
            studentName: 'Alice Student',
            studentEmail: 'alice@example.com',
            textSubmission: 'Submitted repo link',
            fileUrl: '/uploads/work.pdf',
            submittedAt: '2026-11-10T08:00:00Z',
            status: 'SUBMITTED',
          ),
        ],
      },
    );

    final courses = [
      CourseModel(courseId: 10, title: 'Course 1', description: 'First', status: 'PUBLISHED'),
      CourseModel(courseId: 20, title: 'Course 2', description: 'Second', status: 'PUBLISHED'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
          courseRepositoryProvider.overrideWithValue(_FakeCourseRepository(courses)),
          categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepository()),
          enrollmentRepositoryProvider.overrideWithValue(_FakeEnrollmentRepository()),
          instructorRepositoryProvider.overrideWithValue(_FakeInstructorRepository()),
          assignmentRepositoryProvider.overrideWithValue(fakeAssignRepo),
        ],
        child: const MaterialApp(
          home: InstructorStudioScreen(initialTab: 2),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify nonexistent GET /api/assignments endpoint was NOT called
    expect(fakeAssignRepo.getAssignmentsCalled, isFalse);

    // Switch Manage Studio hub to Grading & Submissions
    await tester.tap(find.text('Grading & Submissions'));
    await tester.pumpAndSettle();

    // Submission from second course's assignment must be immediately visible
    expect(find.text('Alice Student'), findsOneWidget);
    expect(find.text('Build REST API (Course 2)'), findsOneWidget);
    expect(find.text('Submitted repo link'), findsOneWidget);
    expect(find.text('Attached Submission File'), findsOneWidget);

    // Open grading dialog
    await tester.ensureVisible(find.text('Grade'));
    await tester.tap(find.text('Grade'));
    await tester.pumpAndSettle();

    expect(find.text('Grade: Alice Student'), findsOneWidget);
    expect(find.text('Open Submitted File'), findsOneWidget);

    // Enter score 92 and feedback, leave letter grade blank for backend auto-calculation
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '92');
    await tester.enterText(fields.at(2), 'Great API design');

    await tester.tap(find.text('Save Grade'));
    await tester.pumpAndSettle();

    expect(fakeAssignRepo.gradedSubmissionId, 501);
    expect(fakeAssignRepo.gradedScore, 92);
    expect(fakeAssignRepo.gradedGrade, '');
    expect(fakeAssignRepo.gradedFeedback, 'Great API design');
  });
}
