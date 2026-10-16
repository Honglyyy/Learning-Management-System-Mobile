import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/course_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/certificate_model.dart';
import '../../../models/course_model.dart';
import '../../../models/enrollment_model.dart';

class MyLearningScreen extends ConsumerStatefulWidget {
  const MyLearningScreen({super.key});

  @override
  ConsumerState<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends ConsumerState<MyLearningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<EnrollmentModel> _inProgress = [];
  List<EnrollmentModel> _completed = [];
  List<EnrollmentModel> _expired = [];
  List<CertificateModel> _certificates = [];
  List<CourseModel> _savedCourses = [];
  ContinueLearningItem? _continueLearning;

  bool _isLoading = true;
  String? _error;

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final parsed = DateTime.parse(date.toString());
      return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final enrollRepo = ref.read(enrollmentRepositoryProvider);
      final certRepo = ref.read(certificateRepositoryProvider);
      final courseRepo = ref.read(courseRepositoryProvider);

      final results = await Future.wait([
        enrollRepo.getMyEnrollments(),
        certRepo.getMyCertificates().catchError((_) => <CertificateModel>[]),
        courseRepo.getFavorites().catchError((_) => <CourseModel>[]),
        enrollRepo.getContinueLearning().catchError((_) => null),
        courseRepo.getCourses().catchError((_) => <CourseModel>[]),
      ]);

      var allEnrollments = results[0] as List<EnrollmentModel>;
      final allCourses = results[4] as List<CourseModel>;
      final courseMap = {for (final c in allCourses) c.courseId: c};

      allEnrollments = allEnrollments.map((e) {
        final course = courseMap[e.courseId];
        final cover = (e.courseCoverUrl != null && e.courseCoverUrl!.isNotEmpty)
            ? e.courseCoverUrl
            : course?.coverUrl;
        final instructor = (e.instructorName != null && e.instructorName!.isNotEmpty)
            ? e.instructorName
            : course?.instructor;

        if (cover != e.courseCoverUrl || instructor != e.instructorName) {
          return e.copyWith(
            courseCoverUrl: cover,
            instructorName: instructor,
          );
        }
        return e;
      }).toList();

      var continueItem = results[3] as ContinueLearningItem?;
      if (continueItem != null && (continueItem.coverUrl == null || continueItem.coverUrl!.isEmpty)) {
        final course = courseMap[continueItem.courseId];
        if (course != null && course.coverUrl != null && course.coverUrl!.isNotEmpty) {
          continueItem = ContinueLearningItem(
            courseId: continueItem.courseId,
            courseTitle: continueItem.courseTitle,
            coverUrl: course.coverUrl,
            lessonId: continueItem.lessonId,
            lessonTitle: continueItem.lessonTitle,
            progressPercent: continueItem.progressPercent,
          );
        }
      }

      if (mounted) {
        setState(() {
          _inProgress = allEnrollments.where((e) => !e.isCompleted && !e.isEnrollmentExpired).toList();
          _completed = allEnrollments.where((e) => e.isCompleted && !e.isEnrollmentExpired).toList();
          _expired = allEnrollments.where((e) => e.isEnrollmentExpired).toList();
          _certificates = results[1] as List<CertificateModel>;
          _savedCourses = results[2] as List<CourseModel>;
          _continueLearning = continueItem;
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

  Future<void> _cancelEnrollment(int courseId) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Cancel Enrollment',
      message: 'Are you sure you want to cancel this enrollment? You will lose access to course progress.',
      confirmLabel: 'Cancel Enrollment',
    );

    if (confirmed == true) {
      try {
        await ref.read(enrollmentRepositoryProvider).cancelEnrollmentMe(courseId);
        ToastService.showSuccess('Enrollment cancelled');
        _loadData();
      } catch (e) {
        ToastService.showError(e.toString());
      }
    }
  }

  Widget _buildContinueBanner(ThemeData theme) {
    if (_continueLearning == null) return const SizedBox.shrink();

    final item = _continueLearning!;
    final cover = mediaUrl(item.coverUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (cover.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: kIsWeb
                    ? Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildContinuePlayIcon(),
                      )
                    : CachedNetworkImage(
                        imageUrl: cover,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _buildContinuePlayIcon(),
                      ),
              ),
            ),
          ] else ...[
            _buildContinuePlayIcon(),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RESUME COURSE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(item.courseTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.progressPercent / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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

  Widget _buildContinuePlayIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
    );
  }

  Widget _buildCoverThumbnail(String? url, {IconData fallbackIcon = Icons.school, double width = 90, double height = 80}) {
    final cover = mediaUrl(url);

    if (cover.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFF1E293B),
        child: Center(child: Icon(fallbackIcon, size: 28, color: Colors.white54)),
      );
    }

    if (kIsWeb) {
      return SizedBox(
        width: width,
        height: height,
        child: Image.network(
          cover,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF1E293B),
            child: Center(child: Icon(fallbackIcon, size: 28, color: Colors.white54)),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: CachedNetworkImage(
        imageUrl: cover,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(color: Colors.grey.withValues(alpha: 0.2)),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFF1E293B),
          child: Center(child: Icon(fallbackIcon, size: 28, color: Colors.white54)),
        ),
      ),
    );
  }

  Widget _buildInProgressTab() {
    if (_inProgress.isEmpty) {
      return const EmptyState(
        title: 'No courses in progress',
        description: 'Explore the course catalog and enroll in courses to start learning.',
      );
    }

    return ListView.builder(
      itemCount: _inProgress.length,
      itemBuilder: (context, index) {
        final item = _inProgress[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildCoverThumbnail(item.courseCoverUrl, width: 90, height: 80),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.courseTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      if (item.instructorName != null)
                        Text(item.instructorName!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item.progressPercent / 100,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${item.progressPercent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (item.expirationDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 12, color: item.isExpiringSoon ? Colors.amber[800] : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Expires: ${_formatDate(item.expirationDate)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: item.isExpiringSoon ? Colors.amber[900] : Colors.grey,
                                fontWeight: item.isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (item.isExpiringSoon) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.daysRemaining == 0 ? 'Today' : '${item.daysRemaining}d left',
                                  style: TextStyle(fontSize: 9, color: Colors.amber[900], fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            onPressed: () => _cancelEnrollment(item.courseId),
                            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => context.push('/courses/${item.courseId}'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                            child: const Text('Continue', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    if (_completed.isEmpty) {
      return const EmptyState(
        title: 'No completed courses yet',
        description: 'Finish all lessons, quizzes, and assignments in a course to complete it.',
      );
    }

    return ListView.builder(
      itemCount: _completed.length,
      itemBuilder: (context, index) {
        final item = _completed[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildCoverThumbnail(item.courseCoverUrl, fallbackIcon: Icons.verified, width: 90, height: 80),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.courseTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text('Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.visibility, size: 14),
                            label: const Text('Course', style: TextStyle(fontSize: 12)),
                            onPressed: () => context.push('/courses/${item.courseId}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpiredTab() {
    if (_expired.isEmpty) {
      return const EmptyState(
        title: 'No expired courses',
        description: 'All your active enrollments are currently valid.',
      );
    }

    return ListView.builder(
      itemCount: _expired.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.history, color: Colors.amber, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your access to these courses has expired. As a returning student, you can re-enroll at an exclusive 50% discount off current prices!',
                    style: TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          );
        }

        final item = _expired[index - 1];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildCoverThumbnail(item.courseCoverUrl, width: 90, height: 85),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule, size: 10, color: Colors.red),
                                SizedBox(width: 3),
                                Text(
                                  'Expired',
                                  style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.courseTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.instructorName != null) ...[
                        const SizedBox(height: 2),
                        Text(item.instructorName!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                      if (item.expirationDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Expired on: ${_formatDate(item.expirationDate)}',
                          style: const TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.replay, size: 14),
                          label: const Text('Renew Access (50% Off)', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          onPressed: () => context.push('/courses/${item.courseId}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCertificatesTab() {
    if (_certificates.isEmpty) {
      return const EmptyState(
        title: 'No certificates issued yet',
        description: 'Complete 100% of any course to earn and claim an official certificate.',
      );
    }

    return ListView.builder(
      itemCount: _certificates.length,
      itemBuilder: (context, index) {
        final cert = _certificates[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cert.courseTitle ?? 'Certificate of Completion',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Certificate Code: ${cert.certificateCode}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (cert.issuedAt != null)
                  Text('Issued: ${Formatters.formatDate(cert.issuedAt)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy Code'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: cert.certificateCode));
                        ToastService.showSuccess('Certificate code copied to clipboard');
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.verified, size: 14),
                      label: const Text('Verify'),
                      onPressed: () => context.push('/verify-certificate?code=${cert.certificateCode}'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 20),
                      tooltip: 'View in browser',
                      onPressed: () async {
                        final url = '${AppConstants.apiBaseUrl}/api/certificates/${cert.certificateCode}/view';
                        final uri = Uri.tryParse(url);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedTab() {
    if (_savedCourses.isEmpty) {
      return const EmptyState(
        title: 'Your wishlist is empty',
        description: 'Explore courses and tap the heart icon to save them for later.',
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: _savedCourses.length,
      itemBuilder: (context, index) {
        final c = _savedCourses[index];
        return CourseCard(
          course: CourseCardItem(
            courseId: c.courseId,
            title: c.title,
            coverUrl: c.coverUrl,
            instructor: c.instructor,
            rating: c.rating,
            price: c.price,
            level: c.level,
            enrollmentCount: c.enrollmentCount,
            accessDurationDays: c.accessDurationDays,
            isFavorite: true,
          ),
          onTap: () => context.push('/courses/${c.courseId}'),
          onFavoriteToggle: () async {
            await ref.read(courseRepositoryProvider).removeFavorite(c.courseId);
            ToastService.showSuccess('Removed from wishlist');
            _loadData();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'In Progress (${_inProgress.length})'),
            Tab(text: 'Completed (${_completed.length})'),
            Tab(text: 'Expired (${_expired.length})'),
            Tab(text: 'Certificates (${_certificates.length})'),
            Tab(text: 'Saved (${_savedCourses.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildContinueBanner(Theme.of(context)),
                    ApiAlert(error: _error, onRetry: _loadData),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildInProgressTab(),
                          _buildCompletedTab(),
                          _buildExpiredTab(),
                          _buildCertificatesTab(),
                          _buildSavedTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
