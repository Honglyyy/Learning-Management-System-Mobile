import 'package:flutter_test/flutter_test.dart';
import 'package:lms_flutter/core/utils/formatters.dart';
import 'package:lms_flutter/core/utils/validators.dart';
import 'package:lms_flutter/core/utils/media_url.dart';

void main() {
  group('Core Utilities Tests', () {
    test('Formatters formatCurrency correctly', () {
      expect(Formatters.formatCurrency(0), 'Free');
      expect(Formatters.formatCurrency(null), 'Free');
      expect(Formatters.formatCurrency(49.99), contains('49.99'));
    });

    test('Formatters formatDuration correctly', () {
      expect(Formatters.formatDuration(0), '00:00');
      expect(Formatters.formatDuration(65), '01:05');
      expect(Formatters.formatDuration(3600), '60:00');
    });

    test('Validators validate email correctly', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('invalid-email'), 'Please enter a valid email address');
      expect(Validators.email('test@example.com'), isNull);
    });

    test('Validators validate password length', () {
      expect(Validators.password('123'), 'Password must be at least 8 characters');
      expect(Validators.password('12345678'), isNull);
    });

    test('mediaUrl resolves URLs properly', () {
      expect(mediaUrl(''), '');
      expect(mediaUrl(null), '');
      expect(mediaUrl('https://example.com/photo.jpg'), 'https://example.com/photo.jpg');
      expect(mediaUrl('/uploads/cover.png'), contains('/uploads/cover.png'));
    });
  });
}
