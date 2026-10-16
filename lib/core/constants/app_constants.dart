class AppConstants {
  // static const String apiBaseUrl = 'https://learning-management-system-fk98.onrender.com';
  static const String apiBaseUrl = 'http://localhost:8080';

  // Storage Keys
  static const String keyToken = 'token';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLastActivity = 'lms_last_activity';
  static const String keyUserEmail = 'user_email';
  static const String keyUserRole = 'user_role';
  static const String keyOnboardingCompleted = 'onboarding_completed';

  // Inactivity & Polling
  static const Duration inactivityTimeout = Duration(minutes: 15);
  static const Duration activityThrottle = Duration(seconds: 5);
  static const Duration inactivityCheckInterval = Duration(seconds: 10);
  static const Duration notificationPollingInterval = Duration(seconds: 15);
  static const Duration videoProgressSaveInterval = Duration(seconds: 5);

  // Pagination defaults
  static const int pageSize = 6;
}
