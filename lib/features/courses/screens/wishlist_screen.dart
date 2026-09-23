import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/course_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/course_model.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  List<CourseModel> _wishlistCourses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final courseRepo = ref.read(courseRepositoryProvider);
      final courses = await courseRepo.getFavorites();
      
      if (mounted) {
        setState(() {
          _wishlistCourses = courses;
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
    try {
      final courseRepo = ref.read(courseRepositoryProvider);
      await courseRepo.removeFavorite(course.courseId);
      
      setState(() {
        _wishlistCourses.removeWhere((c) => c.courseId == course.courseId);
      });
      ToastService.showSuccess('Removed from wishlist');
    } catch (e) {
      ToastService.showError('Failed to remove from wishlist: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
      ),
      body: _isLoading
          ? GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const CourseCardSkeleton(),
            )
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _wishlistCourses.isEmpty
                  ? EmptyState(
                      icon: Icons.favorite_border,
                      title: 'Your wishlist is empty',
                      description: 'Explore courses and add them to your wishlist.',
                      actionLabel: 'Explore Courses',
                      onAction: () => context.pop(),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadWishlist,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _wishlistCourses.length,
                        itemBuilder: (context, index) {
                          final c = _wishlistCourses[index];
                          return CourseCard(
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
                              isFavorite: true,
                            ),
                            isListView: false,
                            onTap: () => context.push('/courses/${c.courseId}'),
                            onFavoriteToggle: () => _toggleFavorite(c),
                          );
                        },
                      ),
                    ),
    );
  }
}
