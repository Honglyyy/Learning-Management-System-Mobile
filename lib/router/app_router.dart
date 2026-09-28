import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers.dart';
import '../core/widgets/app_scaffold.dart';
import '../features/admin/screens/admin_console_screen.dart';
import '../features/assignments/screens/student_assignment_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/verify_otp_screen.dart';
import '../features/certificates/screens/verify_certificate_screen.dart';
import '../features/courses/screens/catalog_screen.dart';
import '../features/courses/screens/wishlist_screen.dart';
import '../features/courses/screens/course_detail_screen.dart';
import '../features/courses/screens/lesson_player_screen.dart';
import '../features/courses/screens/quiz_player_screen.dart';
import '../features/enrollments/screens/my_learning_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/instructor_studio/screens/instructor_studio_screen.dart';
import '../features/instructors/screens/instructor_directory_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/payments/screens/payment_history_screen.dart';
import '../features/profile/screens/student_profile_screen.dart';
import '../features/splash/screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authRepo.isAuthenticated;
      final role = authRepo.getUserRole() ?? 'STUDENT';
      final path = state.uri.path;

      // Admin route guard
      if (path.startsWith('/admin')) {
        if (!isAuth) return '/login?reason=unauthorized';
        if (role != 'ADMIN') return '/';
      }

      // Instructor route guard
      if (path.startsWith('/instructor') && !path.startsWith('/instructors')) {
        if (!isAuth) return '/login?reason=unauthorized';
        if (role != 'INSTRUCTOR' && role != 'ADMIN') return '/';
      }

      // Protected student routes
      if (path.startsWith('/my/') ||
          path.startsWith('/profile') ||
          path.startsWith('/assignments/')) {
        if (!isAuth) return '/login';
      }

      return null;
    },
    routes: [
      // Shell route for main tab navigation screens
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(
            currentPath: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/catalog',
            builder: (context, state) => CatalogScreen(
              initialQuery: state.uri.queryParameters['query'],
              initialCategoryId: int.tryParse(state.uri.queryParameters['categoryId'] ?? ''),
            ),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => CatalogScreen(
              initialQuery: state.uri.queryParameters['query'],
              initialCategoryId: int.tryParse(state.uri.queryParameters['categoryId'] ?? ''),
            ),
          ),
          GoRoute(
            path: '/my/enrollments',
            builder: (context, state) => const MyLearningScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/my/payments',
            builder: (context, state) => const PaymentHistoryScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const StudentProfileScreen(),
          ),
          GoRoute(
            path: '/instructors',
            builder: (context, state) => const InstructorDirectoryScreen(),
          ),
          GoRoute(
            path: '/verify-certificate',
            builder: (context, state) => VerifyCertificateScreen(
              initialCode: state.uri.queryParameters['code'],
            ),
          ),
          GoRoute(
            path: '/instructor',
            builder: (context, state) => const InstructorStudioScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminConsoleScreen(),
          ),
        ],
      ),

      // Standalone Fullscreen Routes
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          reason: state.uri.queryParameters['reason'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => VerifyOtpScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          email: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/courses/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return CourseDetailScreen(courseId: id);
        },
      ),
      GoRoute(
        path: '/courses/:courseId/lessons/:lessonId',
        builder: (context, state) {
          final cId = int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0;
          final lId = int.tryParse(state.pathParameters['lessonId'] ?? '') ?? 0;
          return LessonPlayerScreen(courseId: cId, lessonId: lId);
        },
      ),
      GoRoute(
        path: '/lessons/:lessonId/quiz',
        builder: (context, state) {
          final lId = int.tryParse(state.pathParameters['lessonId'] ?? '') ?? 0;
          return QuizPlayerScreen(lessonId: lId);
        },
      ),
      GoRoute(
        path: '/assignments/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return StudentAssignmentScreen(assignmentId: id);
        },
      ),
    ],
  );
});
