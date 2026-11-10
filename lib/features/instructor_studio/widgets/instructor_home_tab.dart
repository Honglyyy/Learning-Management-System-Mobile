import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../models/course_model.dart';
import '../../../../models/dashboard_models.dart';
import '../../../../models/instructor_model.dart';
import '../../../../models/payment_model.dart';

class InstructorHomeTab extends StatefulWidget {
  final InstructorDashboardDTO? dashboard;
  final InstructorModel? instructorProfile;
  final List<CourseModel> courses;
  final List<PaymentModel> recentPayments;
  final VoidCallback onSearchTap;
  final Function(int tabIndex) onNavigateTab;
  final VoidCallback onOpenCourseCreate;
  final VoidCallback onRefresh;

  const InstructorHomeTab({
    super.key,
    required this.dashboard,
    required this.instructorProfile,
    required this.courses,
    required this.recentPayments,
    required this.onSearchTap,
    required this.onNavigateTab,
    required this.onOpenCourseCreate,
    required this.onRefresh,
  });

  @override
  State<InstructorHomeTab> createState() => _InstructorHomeTabState();
}

class _InstructorHomeTabState extends State<InstructorHomeTab> {
  String _statusFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CourseModel> get _filteredCourses {
    return widget.courses.where((c) {
      final matchesStatus = _statusFilter == 'ALL' ||
          (_statusFilter == 'PUBLISHED' && c.status == 'PUBLISHED') ||
          (_statusFilter == 'DRAFT' && c.status != 'PUBLISHED');

      final matchesQuery = _searchQuery.isEmpty ||
          c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.description.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayName = widget.instructorProfile?.fullName.trim().isNotEmpty == true
        ? widget.instructorProfile!.fullName
        : 'Lay Hongly';
    final avatarUrl = mediaUrl(widget.instructorProfile?.profilePhotoUrl);

    final balanceAmount = (widget.dashboard?.grossRevenue != null && widget.dashboard!.grossRevenue > 0)
        ? widget.dashboard!.grossRevenue.toStringAsFixed(2)
        : '248.75';

    final publishedCount = widget.courses.where((c) => c.status == 'PUBLISHED').length;
    final draftCount = widget.courses.length - publishedCount;
    final filtered = _filteredCourses;

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar / User Greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl.isEmpty
                          ? Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'L',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : const Color(0xFF8F92A1),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF11142D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Search button
                InkWell(
                  onTap: widget.onSearchTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      size: 22,
                      color: isDark ? Colors.white : const Color(0xFF3B67F6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Balance / Revenue Card
            _buildBalanceCardSection(context, displayName, balanceAmount),
            const SizedBox(height: 24),

            // Quick Actions & Stats Bar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onOpenCourseCreate,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Create New Course', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF2F66F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => widget.onNavigateTab(2), // go to Manage tab
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(Icons.video_library_rounded, color: Color(0xFF2F66F6), size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // All Courses Header & Filters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'All Courses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF11142D),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F66F6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.courses.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F66F6),
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab(2),
                  child: const Text('Manage All', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar for Courses
            TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search my courses...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips: ALL, PUBLISHED, DRAFT
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All (${widget.courses.length})', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('PUBLISHED', 'Published ($publishedCount)', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('DRAFT', 'Drafts ($draftCount)', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Course Cards List
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: EmptyState(
                  title: widget.courses.isEmpty ? 'No courses yet' : 'No matching courses',
                  description: widget.courses.isEmpty
                      ? 'Click "+ Create New Course" to build and publish your first course.'
                      : 'Try adjusting your search query or status filter.',
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return _buildCourseCard(context, filtered[index], isDark);
                },
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2F66F6)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2F66F6)
                : (isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : const Color(0xFF4B5563)),
          ),
        ),
      ),
    );
  }

  // --- Course Card for Instructor ---
  Widget _buildCourseCard(BuildContext context, CourseModel course, bool isDark) {
    final isPublished = course.status == 'PUBLISHED';
    final coverImage = mediaUrl(course.coverUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFF1F3F6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => widget.onNavigateTab(2), // Tap to manage materials
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 84,
                      height: 84,
                      color: isDark ? Colors.grey[800] : const Color(0xFFE5E7EB),
                      child: coverImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: coverImage,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const Icon(Icons.school, size: 36, color: Colors.grey),
                            )
                          : const Icon(Icons.school, size: 36, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Course Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status & Level row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPublished
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                course.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isPublished ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                course.level,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              course.price == 0 ? 'Free' : '\$${course.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2F66F6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Title
                        Text(
                          course.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF11142D),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFF1F3F6)),
              const SizedBox(height: 10),

              // Bottom Stats & Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        '${course.enrollmentCount} students',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : const Color(0xFF6B7280)),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        course.rating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[300] : const Color(0xFF374151)),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.play_lesson_outlined, size: 16, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 4),
                      Text(
                        '${course.lessonCount} lessons',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => widget.onNavigateTab(2), // manage materials
                    icon: const Icon(Icons.settings_outlined, size: 14),
                    label: const Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      side: const BorderSide(color: Color(0xFF2F66F6)),
                      foregroundColor: const Color(0xFF2F66F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Plain Earnings Balance Card ---
  Widget _buildBalanceCardSection(BuildContext context, String name, String balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A69F6), Color(0xFF234FE6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF234FE6).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'USD',
                  style: TextStyle(
                    color: Color(0xFF67E8F9),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  balance,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
