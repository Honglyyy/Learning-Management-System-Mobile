import 'package:flutter/material.dart';

class CategoryMeta {
  final IconData icon;
  final Color color;

  const CategoryMeta({
    required this.icon,
    required this.color,
  });

  /// Returns contextual icon and accent color based on category name.
  static CategoryMeta getMeta(String categoryName) {
    final lower = categoryName.trim().toLowerCase();

    if (lower.contains('backend') ||
        lower.contains('server') ||
        lower.contains('api') ||
        lower.contains('node') ||
        lower.contains('django') ||
        lower.contains('spring')) {
      return const CategoryMeta(
        icon: Icons.dns_rounded,
        color: Color(0xFF6366F1), // Indigo
      );
    }
    if (lower.contains('frontend') ||
        lower.contains('front-end') ||
        lower.contains('web') ||
        lower.contains('react') ||
        lower.contains('vue') ||
        lower.contains('angular') ||
        lower.contains('html') ||
        lower.contains('css') ||
        lower.contains('javascript')) {
      return const CategoryMeta(
        icon: Icons.code_rounded,
        color: Color(0xFF06B6D4), // Cyan
      );
    }
    if (lower.contains('mobile') ||
        lower.contains('app') ||
        lower.contains('android') ||
        lower.contains('ios') ||
        lower.contains('flutter') ||
        lower.contains('swift') ||
        lower.contains('kotlin')) {
      return const CategoryMeta(
        icon: Icons.phone_iphone_rounded,
        color: Color(0xFF8B5CF6), // Violet / Purple
      );
    }
    if (lower.contains('fullstack') ||
        lower.contains('full stack') ||
        lower.contains('full-stack') ||
        lower.contains('software')) {
      return const CategoryMeta(
        icon: Icons.layers_rounded,
        color: Color(0xFF3B82F6), // Blue
      );
    }
    if (lower.contains('cloud') ||
        lower.contains('devops') ||
        lower.contains('aws') ||
        lower.contains('azure') ||
        lower.contains('docker') ||
        lower.contains('kubernetes')) {
      return const CategoryMeta(
        icon: Icons.cloud_sync_rounded,
        color: Color(0xFF0EA5E9), // Sky Blue
      );
    }
    if (lower.contains('ai') ||
        lower.contains('artificial') ||
        lower.contains('machine learning') ||
        lower.contains('data') ||
        lower.contains('deep learning') ||
        lower.contains('intelligence')) {
      return const CategoryMeta(
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFFEC4899), // Pink
      );
    }
    if (lower.contains('database') ||
        lower.contains('sql') ||
        lower.contains('mongo') ||
        lower.contains('postgres')) {
      return const CategoryMeta(
        icon: Icons.storage_rounded,
        color: Color(0xFF14B8A6), // Teal
      );
    }
    if (lower.contains('security') ||
        lower.contains('cyber') ||
        lower.contains('ethical') ||
        lower.contains('hacker')) {
      return const CategoryMeta(
        icon: Icons.shield_rounded,
        color: Color(0xFF10B981), // Emerald
      );
    }
    if (lower.contains('design') ||
        lower.contains('ui') ||
        lower.contains('ux') ||
        lower.contains('figma')) {
      return const CategoryMeta(
        icon: Icons.palette_rounded,
        color: Color(0xFFF59E0B), // Amber
      );
    }
    if (lower.contains('game') ||
        lower.contains('unity') ||
        lower.contains('unreal')) {
      return const CategoryMeta(
        icon: Icons.sports_esports_rounded,
        color: Color(0xFFE11D48), // Rose
      );
    }
    if (lower.contains('business') ||
        lower.contains('marketing') ||
        lower.contains('finance')) {
      return const CategoryMeta(
        icon: Icons.trending_up_rounded,
        color: Color(0xFFF97316), // Orange
      );
    }

    return const CategoryMeta(
      icon: Icons.category_rounded,
      color: Color(0xFF3B82F6), // Fallback Blue
    );
  }
}
