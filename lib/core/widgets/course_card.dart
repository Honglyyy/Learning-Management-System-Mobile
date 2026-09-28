import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/formatters.dart';
import '../utils/media_url.dart';

class CourseCardItem {
  final int courseId;
  final String title;
  final String? coverUrl;
  final String? instructor;
  final double rating;
  final num? price;
  final String? level;
  final String? duration;
  final int? enrollmentCount;
  final bool isFavorite;
  final int? accessDurationDays;
  final bool isExpired;
  final num? discountedPrice;
  final bool isEnrolled;

  CourseCardItem({
    required this.courseId,
    required this.title,
    this.coverUrl,
    this.instructor,
    this.rating = 0.0,
    this.price,
    this.level,
    this.duration,
    this.enrollmentCount,
    this.isFavorite = false,
    this.accessDurationDays,
    this.isExpired = false,
    this.discountedPrice,
    this.isEnrolled = false,
  });
}

class CourseCard extends StatelessWidget {
  final CourseCardItem course;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isListView;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.onFavoriteToggle,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = mediaUrl(course.coverUrl);

    if (isListView) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 100,
                    height: 80,
                    child: _buildCoverImage(imageUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (course.isExpired) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('EXPIRED', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (course.level != null) ...[
                            _buildLevelChip(theme, course.level!),
                            const SizedBox(width: 8),
                          ],
                          const Spacer(),
                          if (onFavoriteToggle != null)
                            IconButton(
                              icon: Icon(
                                course.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: course.isFavorite ? Colors.red : theme.hintColor,
                                size: 18,
                              ),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              onPressed: onFavoriteToggle,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      if (course.instructor != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          course.instructor!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildRating(course.rating),
                          if (course.duration != null && course.duration!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.schedule, size: 12, color: theme.hintColor),
                            const SizedBox(width: 3),
                            Text(
                              course.duration!,
                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Icon(Icons.timer_outlined, size: 12, color: theme.hintColor),
                          const SizedBox(width: 3),
                          Text(
                            '${course.accessDurationDays ?? 180}d',
                            style: TextStyle(fontSize: 11, color: theme.hintColor),
                          ),
                          const Spacer(),
                          if (course.isExpired) ...[
                            Text(
                              Formatters.formatCurrency(course.price),
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 11,
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              Formatters.formatCurrency(course.discountedPrice ?? ((course.price ?? 0) * 0.5)),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ] else
                            Text(
                              Formatters.formatCurrency(course.price),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 105,
                  width: double.infinity,
                  child: _buildCoverImage(imageUrl),
                ),
                if (onFavoriteToggle != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Icon(
                          course.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: course.isFavorite ? Colors.red : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                if (course.isExpired)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('EXPIRED', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (course.level != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _buildLevelChip(theme, course.level!, isOverlay: true),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  if (course.instructor != null)
                    Text(
                      course.instructor!,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _buildRating(course.rating),
                      if (course.enrollmentCount != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${course.enrollmentCount})',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (course.duration != null && course.duration!.isNotEmpty) ...[
                        Icon(Icons.schedule, size: 11, color: theme.hintColor),
                        const SizedBox(width: 2),
                        Text(
                          course.duration!,
                          style: TextStyle(fontSize: 10, color: theme.hintColor),
                        ),
                        if (course.accessDurationDays != null) const SizedBox(width: 4),
                      ],
                      if (course.duration == null || course.duration!.isEmpty || course.accessDurationDays != null) ...[
                        Icon(Icons.timer_outlined, size: 11, color: theme.hintColor),
                        const SizedBox(width: 2),
                        Text(
                          '${course.accessDurationDays ?? 180}d',
                          style: TextStyle(fontSize: 10, color: theme.hintColor),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (course.isExpired)
                    Row(
                      children: [
                        Text(
                          Formatters.formatCurrency(course.price),
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 11,
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Formatters.formatCurrency(course.discountedPrice ?? ((course.price ?? 0) * 0.5)),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '-50%',
                            style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      Formatters.formatCurrency(course.price),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(String url) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFF1E293B),
        child: const Center(
          child: Icon(Icons.school, size: 36, color: Colors.white54),
        ),
      );
    }
    
    if (kIsWeb) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1E293B),
          child: const Center(
            child: Icon(Icons.broken_image, size: 32, color: Colors.white54),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) => Container(color: Colors.grey.withValues(alpha: 0.2)),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFF1E293B),
        child: const Center(
          child: Icon(Icons.broken_image, size: 32, color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildLevelChip(ThemeData theme, String level, {bool isOverlay = false}) {
    Color bg = isOverlay ? Colors.black.withValues(alpha: 0.7) : theme.colorScheme.secondary;
    Color fg = isOverlay ? Colors.white : theme.colorScheme.onSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level.replaceAll('_', ' '),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 14),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}
