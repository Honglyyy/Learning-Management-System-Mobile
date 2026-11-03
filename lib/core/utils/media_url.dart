import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/app_constants.dart';

String mediaUrl(String? path) {
  if (path == null || path.trim().isEmpty) return '';
  final trimmed = path.trim();

  // Ignore serialized null/undefined values
  if (trimmed.toLowerCase() == 'null' || trimmed.toLowerCase() == 'undefined') {
    return '';
  }

  String url = trimmed;

  // Full URL or data URI
  if (trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith('data:image/')) {
    url = trimmed;
  } else {
    // Check if string contains a path separator or media extension
    final hasSlash = trimmed.contains('/');
    final hasMediaExt = RegExp(
      r'\.(jpg|jpeg|png|webp|gif|svg|mp4|m4v|mov|webm|m3u8|ts|ogg|mkv|avi|mp3|wav|m4a|aac|flac)(\?.*)?$',
      caseSensitive: false,
    ).hasMatch(trimmed);

    // If it's just arbitrary dummy text without slashes or media extension, it's not a media URL
    if (!hasSlash && !hasMediaExt) {
      return '';
    }

    final base = AppConstants.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    url = '$base$cleanPath';
  }

  // Rewrite localhost for Android emulator
  if (!kIsWeb) {
    try {
      if (Platform.isAndroid) {
        url = url
            .replaceAll('http://localhost:', 'http://10.0.2.2:')
            .replaceAll('http://127.0.0.1:', 'http://10.0.2.2:');
      }
    } catch (_) {}
  }

  return url;
}
