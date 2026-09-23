import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/course_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/category_model.dart';
import '../../../models/course_model.dart';
import '../../../models/enrollment_model.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Filters
  String? _selectedLevel;
  double? _selectedMinRating;
  String? _selectedSort;
  String? _selectedDuration;
  int? _selectedCategoryId;
  bool _isListView = false;

  // Pagination
  int _visibleCount = 6;

  // Data State
  List<CourseModel> _allCourses = [];
  List<CourseModel> _featuredCourses = [];
  List<CourseModel> _popularCourses = [];
  List<CategoryModel> _categories = [];
  ContinueLearningItem? _continueLearning;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _visibleCount = 6);
      }
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final courseRepo = ref.read(courseRepositoryProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final enrollmentRepo = ref.read(enrollmentRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);

      final results = await Future.wait([
        courseRepo.getCourses(),
        courseRepo.getFeatured().catchError((_) => <CourseModel>[]),
        courseRepo.getPopular().catchError((_) => <CourseModel>[]),
        categoryRepo.getCategories().catchError((_) => <CategoryModel>[]),
        if (authRepo.isAuthenticated)
          enrollmentRepo.getContinueLearning().catchError((_) => null)
        else
          Future.value(null),
      ]);

      if (mounted) {
        setState(() {
          _allCourses = results[0] as List<CourseModel>;
          _featuredCourses = results[1] as List<CourseModel>;
          _popularCourses = results[2] as List<CourseModel>;
          _categories = results[3] as List<CategoryModel>;
          _continueLearning = results[4] as ContinueLearningItem?;
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

  Future<void> _fetchFilteredCourses() async {
    try {
      final courseRepo = ref.read(courseRepositoryProvider);
      final courses = await courseRepo.getCourses(
        query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        categoryId: _selectedCategoryId,
        level: _selectedLevel,
        minRating: _selectedMinRating,
        sort: _selectedSort,
      );
      if (mounted) {
        setState(() => _allCourses = courses);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedLevel = null;
      _selectedMinRating = null;
      _selectedSort = null;
      _selectedDuration = null;
      _selectedCategoryId = null;
      _visibleCount = 6;
    });
    _fetchFilteredCourses();
  }

  bool _matchesDuration(CourseModel course, String durationFilter) {
    final d = course.overallDuration?.toLowerCase() ?? '';
    final match = RegExp(r'(\d+)\s*(?:h|hour)').firstMatch(d);
    final hours = match != null ? (int.tryParse(match.group(1) ?? '0') ?? 0) : 0;
    if (durationFilter == 'SHORT') {
      return hours < 3;
    } else if (durationFilter == 'MEDIUM') {
      return hours >= 3 && hours <= 10;
    } else if (durationFilter == 'LONG') {
      return hours > 10;
    }
    return true;
  }

  List<CourseModel> _applyClientFilters(List<CourseModel> courses) {
    var result = List<CourseModel>.from(courses);
    if (_selectedDuration != null) {
      result = result.where((c) => _matchesDuration(c, _selectedDuration!)).toList();
    }
    if (_selectedSort == 'POPULAR') {
      result.sort((a, b) => b.enrollmentCount.compareTo(a.enrollmentCount));
    } else if (_selectedSort == 'RATING') {
      result.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedSort == 'LATEST') {
      result.sort((a, b) => b.courseId.compareTo(a.courseId));
    }
    return result;
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
      _loadInitialData();
    } catch (e) {
      ToastService.showError(e.toString());
    }
  }

  List<CourseModel> _getActiveFeedList() {
    List<CourseModel> baseList;
    switch (_tabController.index) {
      case 1:
        baseList = _featuredCourses;
        break;
      case 2:
        baseList = _popularCourses;
        break;
      default:
        baseList = _allCourses;
        break;
    }
    return _applyClientFilters(baseList);
  }

  Widget _buildContinueLearningBanner(ThemeData theme) {
    if (_continueLearning == null) return const SizedBox.shrink();

    final item = _continueLearning!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONTINUE LEARNING',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.courseTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.progressPercent / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              if (item.lessonId != null) {
                context.push('/courses/${item.courseId}/lessons/${item.lessonId}');
              } else {
                context.push('/courses/${item.courseId}');
              }
            },
            child: const Text('Resume', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: FilterChip(
              label: const Text('All Categories'),
              selected: _selectedCategoryId == null,
              onSelected: (_) {
                setState(() => _selectedCategoryId = null);
                _fetchFilteredCourses();
              },
            ),
          ),
          ..._categories.map((cat) {
            final isSelected = _selectedCategoryId == cat.categoryId;
            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: FilterChip(
                label: Text(cat.category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedCategoryId = selected ? cat.categoryId : null);
                  _fetchFilteredCourses();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final activeFilters = _selectedLevel != null || _selectedMinRating != null || _selectedDuration != null || _selectedSort != null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search courses by title, keywords...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _fetchFilteredCourses();
                          },
                        )
                      : null,
                  isDense: true,
                ),
                onSubmitted: (_) => _fetchFilteredCourses(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(_isListView ? Icons.grid_view : Icons.view_list),
              tooltip: _isListView ? 'Switch to Grid View' : 'Switch to List View',
              onPressed: () => setState(() => _isListView = !_isListView),
            ),
            const SizedBox(width: 4),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filters',
                  onPressed: _showFilterBottomSheet,
                ),
                if (activeFilters)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCategoryChips(),
      ],
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedLevel = null;
                            _selectedMinRating = null;
                            _selectedDuration = null;
                            _selectedSort = null;
                          });
                          setState(() {});
                          _fetchFilteredCourses();
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Level
                  const Text('Level', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLevel,
                    decoration: const InputDecoration(isDense: true),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Levels')),
                      DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
                      DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate')),
                      DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
                    ],
                    onChanged: (val) {
                      setModalState(() => _selectedLevel = val);
                      setState(() {});
                      _fetchFilteredCourses();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Rating
                  const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<double>(
                    value: _selectedMinRating,
                    decoration: const InputDecoration(isDense: true),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Any Rating')),
                      DropdownMenuItem(value: 3.0, child: Text('3.0+ Stars')),
                      DropdownMenuItem(value: 4.0, child: Text('4.0+ Stars')),
                      DropdownMenuItem(value: 4.5, child: Text('4.5+ Stars')),
                    ],
                    onChanged: (val) {
                      setModalState(() => _selectedMinRating = val);
                      setState(() {});
                      _fetchFilteredCourses();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Duration
                  const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedDuration,
                    decoration: const InputDecoration(isDense: true),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Durations')),
                      DropdownMenuItem(value: 'SHORT', child: Text('< 3 Hours')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('3 - 10 Hours')),
                      DropdownMenuItem(value: 'LONG', child: Text('10+ Hours')),
                    ],
                    onChanged: (val) {
                      setModalState(() => _selectedDuration = val);
                      setState(() {});
                      _fetchFilteredCourses();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Sort By
                  const Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSort,
                    decoration: const InputDecoration(isDense: true),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Default')),
                      DropdownMenuItem(value: 'POPULAR', child: Text('Most Popular')),
                      DropdownMenuItem(value: 'RATING', child: Text('Highest Rated')),
                      DropdownMenuItem(value: 'LATEST', child: Text('Latest Courses')),
                    ],
                    onChanged: (val) {
                      setModalState(() => _selectedSort = val);
                      setState(() {});
                      _fetchFilteredCourses();
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCoursesGrid(List<CourseModel> courses) {
    if (courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: EmptyState(
          title: 'No courses found',
          description: 'Try adjusting your search query or filters to find what you are looking for.',
        ),
      );
    }

    final displayed = courses.take(_visibleCount).toList();

    return Column(
      children: [
        if (_isListView)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayed.length,
            itemBuilder: (context, index) {
              final c = displayed[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
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
                    isFavorite: c.isFavorite,
                  ),
                  isListView: true,
                  onTap: () => context.push('/courses/${c.courseId}'),
                  onFavoriteToggle: () => _toggleFavorite(c),
                ),
              );
            },
          )
        else
          LayoutBuilder(builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900
                ? 4
                : constraints.maxWidth > 600
                    ? 3
                    : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: displayed.length,
              itemBuilder: (context, index) {
                final c = displayed[index];
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
                    isFavorite: c.isFavorite,
                  ),
                  isListView: false,
                  onTap: () => context.push('/courses/${c.courseId}'),
                  onFavoriteToggle: () => _toggleFavorite(c),
                );
              },
            );
          }),
        const SizedBox(height: 16),
        if (_visibleCount < courses.length)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _visibleCount += 6),
                child: const Text('Show 6 More'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => setState(() => _visibleCount = courses.length),
                child: Text('Show All (${courses.length})'),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContinueLearningBanner(theme),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'All Courses'),
                  Tab(text: 'Featured'),
                  Tab(text: 'Popular'),
                ],
              ),
              const SizedBox(height: 16),
              _buildFilterBar(),
              const SizedBox(height: 16),
              ApiAlert(error: _error, onRetry: _loadInitialData),
              if (_isLoading)
                LayoutBuilder(builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => const CourseCardSkeleton(),
                  );
                })
              else
                _buildCoursesGrid(_getActiveFeedList()),
            ],
          ),
        ),
      ),
    );
  }
}
