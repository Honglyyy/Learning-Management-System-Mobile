import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_flutter/core/utils/category_utils.dart';
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

    test('CategoryMeta resolves icons and colors for various category names', () {
      final backendMeta = CategoryMeta.getMeta('Backend Development');
      expect(backendMeta.icon, Icons.dns_rounded);
      expect(backendMeta.color, const Color(0xFF6366F1));

      final frontendMeta = CategoryMeta.getMeta('Frontend Web');
      expect(frontendMeta.icon, Icons.code_rounded);
      expect(frontendMeta.color, const Color(0xFF06B6D4));

      final mobileMeta = CategoryMeta.getMeta('Mobile App Development');
      expect(mobileMeta.icon, Icons.phone_iphone_rounded);
      expect(mobileMeta.color, const Color(0xFF8B5CF6));

      final cloudMeta = CategoryMeta.getMeta('Cloud & DevOps');
      expect(cloudMeta.icon, Icons.cloud_sync_rounded);

      final aiMeta = CategoryMeta.getMeta('AI & Machine Learning');
      expect(aiMeta.icon, Icons.auto_awesome_rounded);

      final otherMeta = CategoryMeta.getMeta('General Skills');
      expect(otherMeta.icon, Icons.category_rounded);
    });
  });
}
