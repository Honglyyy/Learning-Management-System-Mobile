import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SessionManager {
  final SharedPreferences _prefs;
  final VoidCallback? onInactivityTimeout;

  DateTime _lastActivityTime = DateTime.now();
  DateTime _lastThrottledWrite = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _checkTimer;

  SessionManager(this._prefs, {this.onInactivityTimeout}) {
    _initLastActivity();
    _startInactivityTimer();
  }

  void _initLastActivity() {
    final savedTimestamp = _prefs.getInt(AppConstants.keyLastActivity);
    if (savedTimestamp != null) {
      _lastActivityTime = DateTime.fromMillisecondsSinceEpoch(savedTimestamp);
    } else {
      recordActivity();
    }
  }

  void recordActivity() {
    final now = DateTime.now();
    _lastActivityTime = now;

    // Throttle writing to SharedPreferences every 5 seconds
    if (now.difference(_lastThrottledWrite) >= AppConstants.activityThrottle) {
      _lastThrottledWrite = now;
      _prefs.setInt(AppConstants.keyLastActivity, now.millisecondsSinceEpoch);
    }
  }

  void _startInactivityTimer() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(AppConstants.inactivityCheckInterval, (_) {
      _checkInactivity();
    });
  }

  void _checkInactivity() {
    final token = _prefs.getString(AppConstants.keyToken);
    if (token == null || token.isEmpty) return;

    final now = DateTime.now();
    final elapsed = now.difference(_lastActivityTime);

    if (elapsed >= AppConstants.inactivityTimeout) {
      _prefs.remove(AppConstants.keyToken);
      _prefs.remove(AppConstants.keyUserRole);
      _prefs.remove(AppConstants.keyUserEmail);
      _prefs.remove(AppConstants.keyLastActivity);
      onInactivityTimeout?.call();
    }
  }

  void dispose() {
    _checkTimer?.cancel();
  }
}
