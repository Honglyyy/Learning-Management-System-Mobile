import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/course_card.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/category_model.dart';
import '../../../models/course_model.dart';
import '../../../models/enrollment_model.dart';
import '../../../models/student_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<CourseModel> _featuredCourses = [];
  List<CourseModel> _popularCourses = [];
  List<CategoryModel> _categories = [];
  ContinueLearningItem? _continueLearning;
  StudentProfile? _profile;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final courseRepo = ref.read(courseRepositoryProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final enrollmentRepo = ref.read(enrollmentRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);
      final studentRepo = ref.read(studentRepositoryProvider);

      final isAuth = authRepo.isAuthenticated;

      final results = await Future.wait([
        courseRepo.getFeatured().catchError((_) => <CourseModel>[]),
        courseRepo.getPopular().catchError((_) => <CourseModel>[]),
        categoryRepo.getCategories().catchError((_) => <CategoryModel>[]),
        if (isAuth)
          enrollmentRepo.getContinueLearning().catchError((_) => null)
        else
          Future.value(null),
        if (isAuth)
          studentRepo.getProfile().then<StudentProfile?>((p) => p).catchError((_) => null)
        else
          Future.value(null),
      ]);

      if (mounted) {
        setState(() {
          _featuredCourses = results[0] as List<CourseModel>;
          _popularCourses = results[1] as List<CourseModel>;
          _categories = results[2] as List<CategoryModel>;
          _continueLearning = results[3] as ContinueLearningItem?;
          _profile = results[4] as StudentProfile?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(CourseModel course) async {
    final authRepo = ref.read(authRepositoryProvider);
    if (!authRepo.isAuthenticated) {
      context.push('/login');
      return;
    }

    final courseRepo = ref.read(courseRepositoryProvider);
    try {
      if (course.isFavorite) {
        await courseRepo.removeFavorite(course.courseId);
        ToastService.showSuccess('Removed from wishlist');
      } else {
        await courseRepo.addFavorite(course.courseId);
        ToastService.showSuccess('Added to wishlist');
      }
      _loadHomeData();
    } catch (e) {
      ToastService.showError(e.toString());
    }
  }

  Widget _buildGreetingHeader(ThemeData theme) {
    final authRepo = ref.watch(authRepositoryProvider);
    final isAuth = authRepo.isAuthenticated;
    final displayName = _profile?.fullName ??
        (isAuth ? authRepo.getUserEmail()?.split('@').first : null) ??
        'Learner';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hello, $displayName',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'What would you like to learn today?',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (isAuth)
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search courses, skills, instructors...',
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune, size: 20),
            onPressed: () => context.go('/catalog'),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (query) {
          if (query.trim().isNotEmpty) {
            context.go('/catalog');
          }
        },
      ),
    );
  }

  Widget _buildContinueLearningCard(ThemeData theme) {
    if (_continueLearning == null) return const SizedBox.shrink();

    final item = _continueLearning!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'CONTINUE LEARNING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${item.progressPercent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.courseTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.lessonTitle != null && item.lessonTitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Next: ${item.lessonTitle}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (item.progressPercent / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Resume Lesson', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                if (item.lessonId != null) {
                  context.push('/courses/${item.courseId}/lessons/${item.lessonId}');
                } else {
                  context.push('/courses/${item.courseId}');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openAllCategoriesSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.hintColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Categories',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.6,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final meta = CategoryMeta.getMeta(cat.category);
                        final isDark = theme.brightness == Brightness.dark;
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            context.go('/catalog?categoryId=${cat.categoryId}');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: meta.color.withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              cat.category,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.go('/catalog');
                      },
                      child: const Text('Explore All Courses in Catalog'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoriesSection(ThemeData theme) {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Explore Categories',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            TextButton(
              onPressed: () => _openAllCategoriesSheet(context, theme),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _categories.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final meta = CategoryMeta.getMeta(cat.category);
                final isDark = theme.brightness == Brightness.dark;

                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => context.go('/catalog?categoryId=${cat.categoryId}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: meta.color.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      cat.category,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHorizontalCourseSection({
    required String title,
    required List<CourseModel> courses,
    required VoidCallback onViewAll,
  }) {
    if (courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: courses.length.clamp(0, 8),
              separatorBuilder: (_, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final c = courses[index];
                return SizedBox(
                  width: 200,
                  child: CourseCard(
                  course: CourseCardItem(
                    courseId: c.courseId,
                    title: c.title,
                    coverUrl: c.coverUrl,
                    instructor: c.instructor,
                    rating: c.rating,
                    price: c.price,
                    level: c.level,
                    duration: c.overallDuration,
                    enrollmentCount: c.enrollmentCount,
                    accessDurationDays: c.accessDurationDays,
                    isExpired: c.isExpired,
                    discountedPrice: c.discountedPrice,
                    isEnrolled: c.isEnrolled,
                    isFavorite: c.isFavorite,
                  ),
                  isListView: false,
                  onTap: () => context.push('/courses/${c.courseId}'),
                  onFavoriteToggle: () => _toggleFavorite(c),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Listen to reactive progress updates to refresh automatically
    ref.listen<int>(courseProgressRefreshProvider, (prev, next) {
      _loadHomeData();
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingHeader(theme),
              _buildSearchBar(theme),
              ApiAlert(error: _error, onRetry: _loadHomeData),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const LoadingSkeleton(width: double.infinity, height: 120),
                const SizedBox(height: 20),
                const LoadingSkeleton(width: double.infinity, height: 40),
                const SizedBox(height: 20),
                const LoadingSkeleton(width: double.infinity, height: 200),
              ] else ...[
                _buildContinueLearningCard(theme),
                _buildCategoriesSection(theme),
                _buildHorizontalCourseSection(
                  title: '🌟 Featured Courses',
                  courses: _featuredCourses,
                  onViewAll: () => context.go('/catalog'),
                ),
                _buildHorizontalCourseSection(
                  title: '🔥 Most Popular',
                  courses: _popularCourses,
                  onViewAll: () => context.go('/catalog'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
