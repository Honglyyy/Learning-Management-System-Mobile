import '../constants/app_constants.dart';

String mediaUrl(String? path) {
  if (path == null || path.trim().isEmpty) return '';
  final trimmed = path.trim();

  // Ignore serialized null/undefined values
  if (trimmed.toLowerCase() == 'null' || trimmed.toLowerCase() == 'undefined') {
    return '';
  }

  // Full URL or data URI
  if (trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith('data:image/')) {
    return trimmed;
  }

  // Check if string contains a path separator or image extension
  final hasSlash = trimmed.contains('/');
  final hasImageExt = RegExp(r'\.(jpg|jpeg|png|webp|gif|svg)(\?.*)?$', caseSensitive: false).hasMatch(trimmed);

  // If it's just arbitrary dummy text (e.g. "asdfgh") without slashes or file extension, it's not an image URL
  if (!hasSlash && !hasImageExt) {
    return '';
  }

  final base = AppConstants.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$base$cleanPath';
}

