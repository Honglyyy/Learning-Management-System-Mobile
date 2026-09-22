import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
  List<CertificateModel> _certificates = [];
  List<CourseModel> _savedCourses = [];
  ContinueLearningItem? _continueLearning;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      ]);

      final allEnrollments = results[0] as List<EnrollmentModel>;

      if (mounted) {
        setState(() {
          _inProgress = allEnrollments.where((e) => !e.isCompleted).toList();
          _completed = allEnrollments.where((e) => e.isCompleted).toList();
          _certificates = results[1] as List<CertificateModel>;
          _savedCourses = results[2] as List<CourseModel>;
          _continueLearning = results[3] as ContinueLearningItem?;
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
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
        final cover = mediaUrl(item.courseCoverUrl);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 90,
                    height: 80,
                    child: cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: cover,
                            fit: BoxFit.cover,
                            placeholder: (context, _) => Container(color: Colors.grey.withValues(alpha: 0.2)),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFF1E293B),
                              child: const Center(child: Icon(Icons.school, size: 28, color: Colors.white54)),
                            ),
                          )
                        : Container(color: Colors.grey.withValues(alpha: 0.2), child: const Icon(Icons.school)),
                  ),
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
        final cover = mediaUrl(item.courseCoverUrl);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 90,
                    height: 80,
                    child: cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: cover,
                            fit: BoxFit.cover,
                            placeholder: (context, _) => Container(color: Colors.grey.withValues(alpha: 0.2)),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFF1E293B),
                              child: const Center(child: Icon(Icons.verified, size: 28, color: Colors.white54)),
                            ),
                          )
                        : Container(color: Colors.grey.withValues(alpha: 0.2), child: const Icon(Icons.verified)),
                  ),
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
        childAspectRatio: 0.72,
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
