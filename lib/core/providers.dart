import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api/api_client.dart';
import 'theme/theme_mode_notifier.dart';
import 'utils/session_manager.dart';

export 'theme/theme_mode_notifier.dart' show sharedPreferencesProvider, themeModeProvider;
import '../repositories/auth_repository.dart';
import '../repositories/course_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/section_repository.dart';
import '../repositories/lesson_repository.dart';
import '../repositories/quiz_repository.dart';
import '../repositories/assignment_repository.dart';
import '../repositories/enrollment_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/certificate_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/student_repository.dart';
import '../repositories/instructor_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/upload_repository.dart';

// Navigation event trigger when session expires
final sessionExpiredEventProvider = StateProvider<String?>((ref) => null);

// Reactive trigger for refreshing course progress across screens
final courseProgressRefreshProvider = StateProvider<int>((ref) => 0);

// ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ApiClient(
    prefs,
    onSessionExpired: (reason) {
      ref.read(sessionExpiredEventProvider.notifier).state = reason;
    },
  );
});

// Session Manager
final sessionManagerProvider = Provider<SessionManager>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SessionManager(
    prefs,
    onInactivityTimeout: () {
      ref.read(sessionExpiredEventProvider.notifier).state = 'inactivity';
    },
  );
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepository(api, prefs);
});

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return CourseRepository(api);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return CategoryRepository(api);
});

final sectionRepositoryProvider = Provider<SectionRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return SectionRepository(api);
});

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return LessonRepository(api);
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return QuizRepository(api);
});

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AssignmentRepository(api);
});

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return EnrollmentRepository(api);
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return PaymentRepository(api);
});

final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return CertificateRepository(api);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return NotificationRepository(api);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return UserRepository(api);
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return StudentRepository(api);
});

final instructorRepositoryProvider = Provider<InstructorRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return InstructorRepository(api);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return DashboardRepository(api);
});

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return UploadRepository(api);
});
