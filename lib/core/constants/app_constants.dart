import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static const String apiBaseUrl = 'https://learning-management-system-fk98.onrender.com';
  /// Base URL for backend API.
  /// Android emulator maps the host machine's 127.0.0.1 to 10.0.2.2.
  // static String get apiBaseUrl {
  //   if (!kIsWeb && Platform.isAndroid) {
  //     return 'http://10.0.2.2:8080';
  //   }
  //   return 'http://localhost:8080';
  // }

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
