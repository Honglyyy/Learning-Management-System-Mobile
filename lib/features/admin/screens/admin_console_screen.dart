import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/crud_panel.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/dashboard_models.dart';
import '../../../models/enrollment_model.dart';
import '../../../models/payment_model.dart';
import '../../../models/user_model.dart';

class AdminConsoleScreen extends ConsumerStatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  ConsumerState<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends ConsumerState<AdminConsoleScreen> {
  int _selectedSectionIndex = 0;

  final List<String> _sectionNames = [
    'Overview',
    'Analytics & Reports',
    'Users & Roles',
    'Courses Catalog',
    'Enrollments',
    'Financials / Payments',
    'Categories',
    'Sections',
    'Lessons',
    'Assignments',
    'Quizzes',
    'Questions',
    'Answers',
  ];

  // Data states
  AdminDashboardDTO? _dashboard;
  EnrollmentReportDTO? _enrollmentReport;
  List<UserModel> _users = [];
  List<EnrollmentModel> _enrollments = [];
  List<PaymentModel> _payments = [];
  String _paymentFilter = 'ALL';

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSection();
  }

  Future<void> _loadSection() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashRepo = ref.read(dashboardRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final enrollRepo = ref.read(enrollmentRepositoryProvider);
      final payRepo = ref.read(paymentRepositoryProvider);

      switch (_selectedSectionIndex) {
        case 0: // Overview
          _dashboard = await dashRepo.getAdminDashboard();
          _enrollmentReport = await dashRepo.getEnrollmentReports().catchError((_) => EnrollmentReportDTO());
          break;
        case 1: // Analytics
          _enrollmentReport = await dashRepo.getEnrollmentReports();
          break;
        case 2: // Users
          _users = await userRepo.getAllUsers();
          break;
        case 3: // Courses
          break;
        case 4: // Enrollments
          _enrollments = await enrollRepo.getAllEnrollments();
          break;
        case 5: // Payments
          _payments = await payRepo.getAllPayments();
          break;
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // --- Section 0: Overview ---
  Widget _buildOverviewSection(ThemeData theme) {
    if (_dashboard == null) return const Center(child: CircularProgressIndicator());
    final d = _dashboard!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Overview', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _buildKpiCard('Total Students', '${d.totalStudents}', Icons.school, Colors.blue),
                _buildKpiCard('Total Instructors', '${d.totalInstructors}', Icons.cast_for_education, Colors.teal),
                _buildKpiCard('Total Courses', '${d.totalCourses}', Icons.menu_book, Colors.orange),
                _buildKpiCard('Gross Revenue', Formatters.formatCurrency(d.grossRevenue), Icons.attach_money, Colors.green),
                _buildKpiCard('Enrollments', '${d.totalEnrollments}', Icons.how_to_reg, Colors.indigo),
                _buildKpiCard('Completion Rate', '${d.completionRate.toStringAsFixed(1)}%', Icons.verified, Colors.amber),
                _buildKpiCard('Total Quizzes', '${d.totalQuizzes}', Icons.quiz, Colors.deepPurple),
                _buildKpiCard('Total Assignments', '${d.totalAssignments}', Icons.assignment, Colors.pink),
              ],
            );
          }),
          const SizedBox(height: 24),
          if (_enrollmentReport != null && _enrollmentReport!.monthlyBreakdown.isNotEmpty) ...[
            Text('Platform Monthly Enrollments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < _enrollmentReport!.monthlyBreakdown.length) {
                                return Text(_enrollmentReport!.monthlyBreakdown[idx].month, style: const TextStyle(fontSize: 10));
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _enrollmentReport!.monthlyBreakdown.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.enrollmentCount.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: theme.colorScheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Section 1: Analytics & Reports ---
  Widget _buildAnalyticsSection(ThemeData theme) {
    if (_enrollmentReport == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System-Wide Reports', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Platform Enrollments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('${_enrollmentReport!.totalEnrollments}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_enrollmentReport!.courseBreakdown.isNotEmpty) ...[
            const Text('Enrollments By Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ..._enrollmentReport!.courseBreakdown.map((cb) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(cb.courseTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Total Enrolled: ${cb.totalEnrolled} • Active: ${cb.activeStudents}', style: const TextStyle(fontSize: 11)),
                    trailing: Text('${cb.completedStudents} Completed', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // --- Section 2: Users & Roles ---
  void _openCreateAdminDialog() {
    final userCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Admin User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username *')),
              const SizedBox(height: 8),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email *')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 8),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password *'), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(userRepositoryProvider).createAdmin({
                  'username': userCtrl.text.trim(),
                  'fullName': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phoneNumber': phoneCtrl.text.trim(),
                  'password': passCtrl.text,
                });
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                ToastService.showSuccess('Admin account created!');
                _loadSection();
              } catch (e) {
                ToastService.showError(e.toString());
              }
            },
            child: const Text('Create Admin'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Users & Access Control', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Admin'),
              onPressed: _openCreateAdminDialog,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _users.isEmpty
              ? const EmptyState(title: 'No users found')
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final u = _users[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(u.username.isNotEmpty ? u.username[0].toUpperCase() : 'U')),
                        title: Text(u.fullName ?? u.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${u.email} • Role: ${u.role}', style: const TextStyle(fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: u.role,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(value: 'STUDENT', child: Text('STUDENT', style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(value: 'INSTRUCTOR', child: Text('INSTRUCTOR', style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN', style: TextStyle(fontSize: 11))),
                              ],
                              onChanged: (newRole) async {
                                if (newRole != null && newRole != u.role) {
                                  await ref.read(userRepositoryProvider).changeUserRole(u.id, newRole);
                                  ToastService.showSuccess('Role updated to $newRole');
                                  _loadSection();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              onPressed: () async {
                                final confirmed = await ConfirmationDialog.show(
                                  context,
                                  title: 'Delete User',
                                  message: 'Are you sure you want to delete ${u.username}?',
                                );
                                if (confirmed == true) {
                                  await ref.read(userRepositoryProvider).deleteUser(u.id);
                                  ToastService.showSuccess('User deleted');
                                  _loadSection();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- Section 4: Enrollments Management ---
  Widget _buildEnrollmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enrollments Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(
          child: _enrollments.isEmpty
              ? const EmptyState(title: 'No enrollments records')
              : ListView.builder(
                  itemCount: _enrollments.length,
                  itemBuilder: (context, index) {
                    final e = _enrollments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${e.userName ?? "Student"} → ${e.courseTitle}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('Status: ${e.status} • Progress: ${e.progressPercent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
                        trailing: DropdownButton<String>(
                          value: e.status,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE', style: TextStyle(fontSize: 11))),
                            DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED', style: TextStyle(fontSize: 11))),
                            DropdownMenuItem(value: 'EXPIRED', child: Text('EXPIRED', style: TextStyle(fontSize: 11))),
                            DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED', style: TextStyle(fontSize: 11))),
                          ],
                          onChanged: (newStatus) async {
                            if (newStatus != null && newStatus != e.status) {
                              await ref.read(enrollmentRepositoryProvider).updateEnrollmentStatus(e.enrollmentId, newStatus);
                              ToastService.showSuccess('Status updated');
                              _loadSection();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- Section 5: Financials / Payments ---
  Widget _buildPaymentsSection() {
    final filtered = _payments.where((p) {
      if (_paymentFilter == 'ALL') return true;
      return p.status == _paymentFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Financials / Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _paymentFilter,
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Payments')),
                DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                DropdownMenuItem(value: 'FAILED', child: Text('Failed')),
              ],
              onChanged: (val) => setState(() => _paymentFilter = val ?? 'ALL'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(title: 'No payment records found')
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${p.studentName ?? "Student"} • ${Formatters.formatCurrency(p.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${p.courseTitle} • ${p.provider} • Ref: ${p.providerReference ?? "-"}', style: const TextStyle(fontSize: 11)),
                        trailing: DropdownButton<String>(
                          value: p.status,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(value: 'PAID', child: Text('PAID', style: TextStyle(fontSize: 11, color: Colors.green))),
                            DropdownMenuItem(value: 'PENDING', child: Text('PENDING', style: TextStyle(fontSize: 11, color: Colors.orange))),
                            DropdownMenuItem(value: 'FAILED', child: Text('FAILED', style: TextStyle(fontSize: 11, color: Colors.red))),
                          ],
                          onChanged: (newStatus) async {
                            if (newStatus != null && newStatus != p.status) {
                              await ref.read(paymentRepositoryProvider).updatePaymentStatus(p.paymentId, newStatus);
                              ToastService.showSuccess('Payment status updated');
                              _loadSection();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- Helper: Generic CRUD Panel Builder ---
  Widget _buildGenericCrudPanel(String resource, String title, String idKey, List<CrudFieldDef> fields, List<CrudColumnDef> columns) {
    final client = ref.read(apiClientProvider);

    return CrudPanel(
      config: CrudConfig(
        title: title,
        idKey: idKey,
        fields: fields,
        columns: columns,
        fetchList: () async {
          final res = await client.get('/api/$resource');
          if (res is List) {
            return res.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          }
          return [];
        },
        createItem: (body) async {
          await client.post('/api/$resource', data: body);
        },
        updateItem: (id, body) async {
          await client.put('/api/$resource/$id', data: body);
        },
        deleteItem: (id) async {
          await client.delete('/api/$resource/$id');
        },
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Console: ${_sectionNames[_selectedSectionIndex]}')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.admin_panel_settings, color: Colors.white, size: 36),
                  SizedBox(height: 10),
                  Text('Admin Console', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('13 System Management Panels', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            ..._sectionNames.asMap().entries.map((entry) {
              final idx = entry.key;
              final name = entry.value;
              final isSelected = _selectedSectionIndex == idx;

              return ListTile(
                dense: true,
                selected: isSelected,
                title: Text(name),
                onTap: () {
                  setState(() => _selectedSectionIndex = idx);
                  Navigator.of(context).pop();
                  _loadSection();
                },
              );
            }),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ApiAlert(error: _error, onRetry: _loadSection),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : [
                      _buildOverviewSection(Theme.of(context)),
                      _buildAnalyticsSection(Theme.of(context)),
                      _buildUsersSection(),
                      _buildGenericCrudPanel(
                        'courses',
                        'Courses Catalog',
                        'courseId',
                        [
                          CrudFieldDef(name: 'title', label: 'Title'),
                          CrudFieldDef(name: 'description', label: 'Description', type: CrudFieldType.textarea),
                          CrudFieldDef(name: 'price', label: 'Price (USD)', type: CrudFieldType.number),
                          CrudFieldDef(name: 'overallDuration', label: 'Duration'),
                          CrudFieldDef(name: 'accessDurationDays', label: 'Access (Days)', type: CrudFieldType.number),
                          CrudFieldDef(name: 'instructorId', label: 'Instructor ID', type: CrudFieldType.number),
                        ],
                        [
                          CrudColumnDef(key: 'title', label: 'Title'),
                          CrudColumnDef(key: 'price', label: 'Price', render: (row) => Text(Formatters.formatCurrency(row['price']))),
                          CrudColumnDef(key: 'accessDurationDays', label: 'Access', render: (row) => Text('${row['accessDurationDays'] ?? 180}d')),
                          CrudColumnDef(key: 'status', label: 'Status'),
                        ],
                      ),
                      _buildEnrollmentsSection(),
                      _buildPaymentsSection(),
                      _buildGenericCrudPanel(
                        'categories',
                        'Categories',
                        'categoryId',
                        [CrudFieldDef(name: 'category', label: 'Category Name')],
                        [CrudColumnDef(key: 'category', label: 'Category Name')],
                      ),
                      _buildGenericCrudPanel(
                        'sections',
                        'Sections',
                        'sectionId',
                        [
                          CrudFieldDef(name: 'title', label: 'Section Title'),
                          CrudFieldDef(name: 'courseId', label: 'Course ID', type: CrudFieldType.number),
                          CrudFieldDef(name: 'orderIndex', label: 'Order', type: CrudFieldType.number),
                        ],
                        [
                          CrudColumnDef(key: 'title', label: 'Title'),
                          CrudColumnDef(key: 'courseId', label: 'Course ID'),
                        ],
                      ),
                      _buildGenericCrudPanel(
                        'lessons',
                        'Lessons',
                        'lessonId',
                        [
                          CrudFieldDef(name: 'title', label: 'Lesson Title'),
                          CrudFieldDef(name: 'sectionId', label: 'Section ID', type: CrudFieldType.number),
                          CrudFieldDef(name: 'duration', label: 'Duration'),
                          CrudFieldDef(name: 'isFree', label: 'Free Preview', type: CrudFieldType.checkbox, isRequired: false),
                        ],
                        [
                          CrudColumnDef(key: 'title', label: 'Title'),
                          CrudColumnDef(key: 'duration', label: 'Duration'),
                        ],
                      ),
                      _buildGenericCrudPanel(
                        'assignments',
                        'Assignments',
                        'assignmentId',
                        [
                          CrudFieldDef(name: 'title', label: 'Assignment Title'),
                          CrudFieldDef(name: 'courseId', label: 'Course ID', type: CrudFieldType.number),
                          CrudFieldDef(name: 'maxScore', label: 'Max Score', type: CrudFieldType.number),
                        ],
                        [
                          CrudColumnDef(key: 'title', label: 'Title'),
                          CrudColumnDef(key: 'maxScore', label: 'Max Score'),
                        ],
                      ),
                      _buildGenericCrudPanel(
                        'quizzes',
                        'Quizzes',
                        'quizId',
                        [
                          CrudFieldDef(name: 'quizTitle', label: 'Quiz Title'),
                          CrudFieldDef(name: 'lessonId', label: 'Lesson ID', type: CrudFieldType.number),
                          CrudFieldDef(name: 'totalPoint', label: 'Total Points', type: CrudFieldType.number),
                        ],
                        [
                          CrudColumnDef(key: 'quizTitle', label: 'Quiz Title'),
                          CrudColumnDef(key: 'totalPoint', label: 'Total Points'),
                        ],
                      ),
                      _buildGenericCrudPanel(
                        'questions',
                        'Questions',
                        'questionId',
                        [
                          CrudFieldDef(name: 'questionText', label: 'Question Text'),
                          CrudFieldDef(name: 'quizId', label: 'Quiz ID', type: CrudFieldType.number),
                          CrudFieldDef(name: 'point', label: 'Points', type: CrudFieldType.number),
                        ],
                        [
                          CrudColumnDef(key: 'questionText', label: 'Question Text'),
                          CrudColumnDef(key: 'point', label: 'Points'),
                        ],
                      ),
                      _buildGenericCrudPanel(
                        'answers',
                        'Answers',
                        'answerId',
                        [
                          CrudFieldDef(name: 'answerText', label: 'Answer Text'),
                          CrudFieldDef(name: 'questionId', label: 'Question ID', type: CrudFieldType.number),
                          CrudFieldDef(name: 'isCorrect', label: 'Is Correct Answer', type: CrudFieldType.checkbox, isRequired: false),
                        ],
                        [
                          CrudColumnDef(key: 'answerText', label: 'Answer Text'),
                          CrudColumnDef(key: 'isCorrect', label: 'Correct', render: (row) => Text('${row['isCorrect'] == true}')),
                        ],
                      ),
                    ][_selectedSectionIndex],
            ),
          ],
        ),
      ),
    );
  }
}
