import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../models/course_model.dart';
import '../../../../models/dashboard_models.dart';

class InstructorAnalyticTab extends StatefulWidget {
  final InstructorDashboardDTO? dashboard;
  final EnrollmentReportDTO? enrollmentReport;
  final QuizReportDTO? quizReport;
  final List<CourseModel> courses;
  final VoidCallback onBackTap;
  final VoidCallback onRefresh;

  const InstructorAnalyticTab({
    super.key,
    required this.dashboard,
    required this.enrollmentReport,
    required this.quizReport,
    this.courses = const [],
    required this.onBackTap,
    required this.onRefresh,
  });

  @override
  State<InstructorAnalyticTab> createState() => _InstructorAnalyticTabState();
}

class _InstructorAnalyticTabState extends State<InstructorAnalyticTab> {
  String _selectedFilter = 'This Month';

  final List<Color> _palette = const [
    Color(0xFF2563EB), // Royal Blue
    Color(0xFF00C6FF), // Cyan
    Color(0xFFEF4444), // Coral Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
  ];

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select Time Range',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              ...['This Week', 'This Month', 'Last 30 Days', 'This Year', 'All Time'].map(
                (f) => ListTile(
                  title: Text(f),
                  trailing: _selectedFilter == f
                      ? const Icon(Icons.check, color: Color(0xFF3B67F6))
                      : null,
                  onTap: () {
                    setState(() => _selectedFilter = f);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate student numbers
    int totalStudents = widget.dashboard?.totalStudents ?? 0;
    if (totalStudents == 0 && widget.courses.isNotEmpty) {
      totalStudents = widget.courses.fold<int>(0, (sum, c) => sum + c.enrollmentCount);
    }
    if (totalStudents == 0 && widget.enrollmentReport != null && widget.enrollmentReport!.totalEnrollments > 0) {
      totalStudents = widget.enrollmentReport!.totalEnrollments;
    }

    final avgRating = (widget.dashboard?.averageRating != null && widget.dashboard!.averageRating > 0)
        ? widget.dashboard!.averageRating
        : (widget.courses.isNotEmpty
            ? widget.courses.fold<double>(0.0, (sum, c) => sum + c.rating) / widget.courses.length
            : 4.8);

    final totalCourses = (widget.dashboard?.totalCourses != null && widget.dashboard!.totalCourses > 0)
        ? widget.dashboard!.totalCourses
        : widget.courses.length;

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar: Back Button, Title 'Dashboard', Filter Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: widget.onBackTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: isDark ? Colors.white : const Color(0xFF11142D),
                    ),
                  ),
                ),
                Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF11142D),
                  ),
                ),
                InkWell(
                  onTap: _showFilterSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: isDark ? Colors.white : const Color(0xFF11142D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Card 1: Students Pie Chart & Statistics
            _buildStudentsDistributionCard(
              context,
              isDark,
              totalStudents: totalStudents,
              avgRating: avgRating,
              totalCourses: totalCourses,
            ),
            const SizedBox(height: 26),

            // Section 2: Student Growth / Transactions Line Chart
            Text(
              'Student Growth & Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF11142D),
              ),
            ),
            const SizedBox(height: 14),
            _buildTransactionsLineChartCard(context, isDark),
            const SizedBox(height: 24),

            // Assessment Performance
            if (widget.quizReport != null && widget.quizReport!.totalQuizzes > 0) ...[
              Text(
                'Assessment Performance',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF11142D),
                ),
              ),
              const SizedBox(height: 12),
              _buildQuizOverviewCard(isDark),
              const SizedBox(height: 20),
            ],

            // Course Breakdown with Student Counts
            Text(
              'Students Enrolled Per Course',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF11142D),
              ),
            ),
            const SizedBox(height: 12),
            _buildCourseBreakdownList(isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- Students Distribution Pie Chart Card ---
  Widget _buildStudentsDistributionCard(
    BuildContext context,
    bool isDark, {
    required int totalStudents,
    required double avgRating,
    required int totalCourses,
  }) {
    // Build pie chart slices from courses breakdown or courses list
    final List<Map<String, dynamic>> courseData = [];

    if (widget.enrollmentReport != null && widget.enrollmentReport!.courseBreakdown.isNotEmpty) {
      for (final cb in widget.enrollmentReport!.courseBreakdown) {
        courseData.add({
          'title': cb.courseTitle,
          'count': cb.totalEnrolled,
        });
      }
    } else if (widget.courses.isNotEmpty) {
      for (final c in widget.courses) {
        courseData.add({
          'title': c.title,
          'count': c.enrollmentCount,
        });
      }
    }

    // Prepare slices
    List<PieChartSectionData> sections = [];
    int sumCount = courseData.fold<int>(0, (sum, item) => sum + (item['count'] as int));

    if (sumCount > 0) {
      for (int i = 0; i < courseData.length; i++) {
        final item = courseData[i];
        final count = item['count'] as int;
        if (count == 0) continue;
        final color = _palette[i % _palette.length];
        final percent = (count / sumCount * 100);

        sections.add(
          PieChartSectionData(
            color: color,
            value: count.toDouble(),
            showTitle: false,
            radius: 36,
            badgeWidget: _buildBadgePill('${percent.toStringAsFixed(0)}%', color),
            badgePositionPercentageOffset: 0.95,
          ),
        );
      }
    }

    // Fallback slices if all counts are 0 or no courses yet
    if (sections.isEmpty) {
      if (courseData.isNotEmpty) {
        for (int i = 0; i < courseData.length.clamp(0, 4); i++) {
          final color = _palette[i % _palette.length];
          sections.add(
            PieChartSectionData(
              color: color,
              value: 1,
              showTitle: false,
              radius: 34,
            ),
          );
        }
      } else {
        sections = [
          PieChartSectionData(color: const Color(0xFF2563EB), value: 40, showTitle: false, radius: 36),
          PieChartSectionData(color: const Color(0xFF00C6FF), value: 24, showTitle: false, radius: 36),
          PieChartSectionData(color: const Color(0xFFEF4444), value: 36, showTitle: false, radius: 36),
        ];
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFF1F3F6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Donut Pie Chart with percentage badges
          SizedBox(
            height: 170,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Total Students Amount display
          Text(
            '$totalStudents',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF11142D),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Total Enrolled Students',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : const Color(0xFF8F92A1),
            ),
          ),
          const SizedBox(height: 16),

          // Legend for courses in pie chart
          if (courseData.isNotEmpty) ...[
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: courseData.take(4).map((c) {
                final idx = courseData.indexOf(c);
                final color = _palette[idx % _palette.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${c['title']}: ${c['count']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Divider
          Divider(color: isDark ? Colors.white12 : const Color(0xFFF1F3F6), height: 1),
          const SizedBox(height: 18),

          // 3 Column Metrics Row: Total Students, Avg Rating, Total Courses
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryColumn(
                label: 'Students',
                value: '$totalStudents',
                valueColor: const Color(0xFF1E3A8A),
                isDark: isDark,
              ),
              _buildSummaryColumn(
                label: 'Avg Rating',
                value: '★ ${avgRating.toStringAsFixed(1)}',
                valueColor: const Color(0xFFD97706),
                isDark: isDark,
              ),
              _buildSummaryColumn(
                label: 'Courses',
                value: '$totalCourses',
                valueColor: const Color(0xFFEF4444),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgePill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSummaryColumn({
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : const Color(0xFF8F92A1),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // --- Transactions & Growth Line Chart ---
  Widget _buildTransactionsLineChartCard(BuildContext context, bool isDark) {
    final spots = const [
      FlSpot(20, 2600),
      FlSpot(20.6, 2750),
      FlSpot(21, 2300),
      FlSpot(21.5, 1750),
      FlSpot(22, 2100),
      FlSpot(23, 3100),
      FlSpot(23.6, 2900),
      FlSpot(24, 3050),
      FlSpot(25, 2930),
      FlSpot(26, 3300),
    ];

    final lineBarData = LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: const Color(0xFF3B67F6),
      barWidth: 2.8,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        checkToShowDot: (spot, barData) => spot.x == 25,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 5,
            color: const Color(0xFF3B67F6),
            strokeWidth: 2.5,
            strokeColor: Colors.white,
          );
        },
      ),
    );

    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 16, right: 18, left: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFF1F3F6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    minX: 20,
                    maxX: 26,
                    minY: 1400,
                    maxY: 4200,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: 500,
                          getTitlesWidget: (val, meta) {
                            final rounded = val.toInt();
                            if (rounded % 500 == 0 && rounded >= 1500 && rounded <= 4000) {
                              return Text(
                                '$rounded',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (val, meta) {
                            final day = val.toInt();
                            final isHighlight = day == 25;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                                  color: isHighlight
                                      ? (isDark ? Colors.white : const Color(0xFF11142D))
                                      : (isDark ? Colors.grey[500] : const Color(0xFF9CA3AF)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [lineBarData],
                  ),
                ),

                // Tooltip indicator badge for "2930" on day 25
                Positioned(
                  right: 48,
                  top: 72,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '2930',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF11142D),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizOverviewCard(bool isDark) {
    final q = widget.quizReport!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFF1F3F6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text('${q.totalQuizzes}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text('Quizzes', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          Column(
            children: [
              Text('${q.overallPassRate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              const SizedBox(height: 3),
              Text('Pass Rate', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          Column(
            children: [
              Text('${q.averageScore.toStringAsFixed(1)} pts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3B67F6))),
              const SizedBox(height: 3),
              Text('Avg Score', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  // List of Courses with Student Breakdown
  Widget _buildCourseBreakdownList(bool isDark) {
    if (widget.courses.isEmpty &&
        (widget.enrollmentReport == null || widget.enrollmentReport!.courseBreakdown.isEmpty)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No courses found')),
      );
    }

    if (widget.enrollmentReport != null && widget.enrollmentReport!.courseBreakdown.isNotEmpty) {
      return Column(
        children: widget.enrollmentReport!.courseBreakdown.map((cb) {
          final idx = widget.enrollmentReport!.courseBreakdown.indexOf(cb);
          final color = _palette[idx % _palette.length];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFF1F3F6),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.school, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cb.courseTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF11142D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Enrolled: ${cb.totalEnrolled} • Active: ${cb.activeStudents}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${cb.completedStudents} done',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: widget.courses.map((c) {
        final idx = widget.courses.indexOf(c);
        final color = _palette[idx % _palette.length];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFF1F3F6),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.menu_book, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF11142D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Rating: ★ ${c.rating.toStringAsFixed(1)} • ${c.lessonCount} lessons',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Text(
                '${c.enrollmentCount} students',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
