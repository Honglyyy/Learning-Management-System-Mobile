class ApiEndpoints {
  // Auth
  static const String authenticate = '/authenticate';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String resendOtp = '/resend-otp';
  static const String sendResetOtp = '/send-reset-otp';
  static const String resetPassword = '/reset-password';
  static const String adminRegister = '/admin/register';
  static const String authSession = '/api/auth/session';
  static const String authLogout = '/api/auth/logout';

  // Users
  static const String users = '/api/users';
  static String userById(int id) => '/api/users/$id';
  static String userRole(int id) => '/api/users/$id/role';
  static const String changePassword = '/api/users/change-password';
  static const String userActivities = '/api/users/activities';

  // Student Profile
  static const String studentProfile = '/api/students/profile';
  static const String studentProfilePhoto = '/api/students/profile/photo';

  // Instructors
  static const String instructors = '/api/instructors';
  static String instructorById(int id) => '/api/instructors/$id';
  static const String instructorMe = '/api/instructors/me';
  static const String instructorMePhoto = '/api/instructors/me/photo';

  // Courses
  static const String courses = '/api/courses';
  static String courseById(int id) => '/api/courses/$id';
  static const String coursesFeatured = '/api/courses/featured';
  static const String coursesPopular = '/api/courses/popular';
  static const String coursesSearch = '/api/courses/search';
  static const String coursesMyLearning = '/api/courses/my-learning';
  static String courseStatus(int id) => '/api/courses/$id/status';
  static String courseReviews(int id) => '/api/courses/$id/reviews';
  static String courseReviewSubmit(int id) => '/api/courses/$id/review';
  static String courseProgress(int id) => '/api/courses/$id/progress';
  static String courseLessonsStatus(int id) => '/api/courses/$id/lessons-status';
  static String courseAssignments(int id) => '/api/courses/$id/assignments';
  static String courseEnrollments(int id) => '/api/courses/$id/enrollments';

  // Instructor Courses
  static const String instructorCoursesMe = '/api/courses/instructor/me';
  static String instructorCourseMeById(int id) => '/api/courses/instructor/me/$id';

  // Categories
  static const String categories = '/api/categories';
  static String categoryById(int id) => '/api/categories/$id';

  // Sections
  static const String sections = '/api/sections';
  static String sectionById(int id) => '/api/sections/$id';
  static const String instructorSectionsMe = '/api/sections/instructor/me';
  static String instructorSectionMeById(int id) => '/api/sections/instructor/me/$id';

  // Lessons
  static const String lessons = '/api/lessons';
  static String lessonById(int id) => '/api/lessons/$id';
  static const String instructorLessonsMe = '/api/lessons/instructor/me';
  static String instructorLessonMeById(int id) => '/api/lessons/instructor/me/$id';
  static String lessonNavigation(int id) => '/api/lessons/$id/navigation';
  static String lessonProgress(int id) => '/api/lessons/$id/progress';
  static String lessonComplete(int id) => '/api/lessons/$id/complete';
  static String lessonMaterials(int id) => '/api/lessons/$id/materials';
  static String lessonQuiz(int id) => '/api/lessons/$id/quiz';
  static String materialById(int id) => '/api/materials/$id';

  // Quizzes & Assessments
  static const String quizzes = '/api/quizzes';
  static String quizById(int id) => '/api/quizzes/$id';
  static String quizAttemptMe(int quizId) => '/api/quizzes/$quizId/attempt/me';
  static String quizSubmit(int quizId) => '/api/quizzes/$quizId/submit';
  static const String questions = '/api/questions';
  static String questionById(int id) => '/api/questions/$id';
  static const String answers = '/api/answers';
  static String answerById(int id) => '/api/answers/$id';

  // Assignments
  static const String assignments = '/api/assignments';
  static String assignmentById(int id) => '/api/assignments/$id';
  static String assignmentSubmissionMe(int id) => '/api/assignments/$id/submission/me';
  static String assignmentSubmit(int id) => '/api/assignments/$id/submit';
  static String assignmentSubmissions(int id) => '/api/assignments/$id/submissions';
  static String gradeSubmission(int submissionId) => '/api/assignments/submissions/$submissionId/grade';

  // Enrollments
  static const String enrollmentsMe = '/api/enrollments/me';
  static String cancelEnrollmentMe(int courseId) => '/api/enrollments/me/courses/$courseId';
  static const String enrollments = '/api/enrollments';
  static String enrollmentById(int id) => '/api/enrollments/$id';
  static String enrollmentStatus(int id) => '/api/enrollments/$id/status';
  static const String enrollmentsManage = '/api/enrollments/manage';
  static const String learningContinue = '/api/learning/continue';

  // Payments
  static const String paymentsCheckout = '/api/payments/checkout';
  static const String paymentsCheckoutQuote = '/api/payments/checkout/quote';
  static String paymentConfirm(int paymentId) => '/api/payments/$paymentId/confirm';
  static const String paymentsMe = '/api/payments/me';
  static const String payments = '/api/payments';
  static String paymentById(int id) => '/api/payments/$id';

  // Certificates & Favorites
  static const String certificatesMe = '/api/certificates/me';
  static String certificateClaim(int courseId) => '/api/certificates/claim/$courseId';
  static String certificateVerify(String code) => '/api/certificates/verify/$code';
  static String certificateView(String code) => '/api/certificates/$code/view';
  static const String favorites = '/api/favorites';
  static String favoriteCheck(int courseId) => '/api/favorites/check/$courseId';
  static String favoriteById(int courseId) => '/api/favorites/$courseId';

  // Notifications
  static const String notificationsUnreadCount = '/api/notifications/unread-count';
  static const String notifications = '/api/notifications';
  static String notificationRead(int id) => '/api/notifications/$id/read';
  static const String notificationsReadAll = '/api/notifications/read-all';

  // Dashboards & Reports
  static const String dashboardAdmin = '/api/dashboard/admin';
  static const String dashboardInstructor = '/api/dashboard/instructor';
  static const String dashboardStudent = '/api/dashboard/student';
  static const String reportsEnrollments = '/api/reports/enrollments';
  static const String reportsProgress = '/api/reports/progress';
  static const String reportsQuizzes = '/api/reports/quizzes';

  // Uploads
  static const String uploadCourseCover = '/api/uploads/course-cover';
  static const String uploadLessonVideo = '/api/uploads/lesson-video';
  static const String uploadMaterial = '/api/uploads/material';
  static const String uploadAssignmentFile = '/api/uploads/assignment-file';
}
