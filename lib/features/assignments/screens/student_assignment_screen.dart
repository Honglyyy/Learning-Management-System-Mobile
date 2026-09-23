import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/assignment_model.dart';

class StudentAssignmentScreen extends ConsumerStatefulWidget {
  final int assignmentId;

  const StudentAssignmentScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<StudentAssignmentScreen> createState() => _StudentAssignmentScreenState();
}

class _StudentAssignmentScreenState extends ConsumerState<StudentAssignmentScreen> {
  AssignmentModel? _assignment;
  AssignmentSubmissionModel? _submission;

  final _textSubmissionController = TextEditingController();
  File? _selectedFile;
  String? _uploadedFileUrl;
  String? _uploadedFilePublicId;

  bool _isLoading = true;
  bool _isUploading = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  @override
  void dispose() {
    _textSubmissionController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assignRepo = ref.read(assignmentRepositoryProvider);
      final assignmentRes = await ref.read(apiClientProvider).get('/api/assignments/${widget.assignmentId}');
      final assignment = AssignmentModel.fromJson(assignmentRes as Map<String, dynamic>);
      final submission = await assignRepo.getSubmissionMe(widget.assignmentId);

      if (mounted) {
        setState(() {
          _assignment = assignment;
          _submission = submission;
          if (submission != null && submission.textSubmission != null) {
            _textSubmissionController.text = submission.textSubmission!;
          }
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

  Future<void> _pickAndUploadFile() async {
    final fileResult = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'zip', 'txt'],
    );

    if (fileResult != null) {
      setState(() {
        _selectedFile = kIsWeb || fileResult.path == null ? null : File(fileResult.path!);
        _isUploading = true;
      });

      try {
        final uploadRepo = ref.read(uploadRepositoryProvider);
        Map<String, String> uploadRes;
        
        if (kIsWeb) {
          final bytes = await fileResult.readAsBytes();
          uploadRes = await uploadRepo.uploadAssignmentFileBytes(bytes, fileResult.name);
        } else {
          final file = File(fileResult.path!);
          uploadRes = await uploadRepo.uploadAssignmentFile(file);
        }

        if (mounted) {
          setState(() {
            _uploadedFileUrl = uploadRes['url'];
            _uploadedFilePublicId = uploadRes['publicId'];
            _isUploading = false;
          });
          ToastService.showSuccess('File uploaded successfully');
        }
      } catch (e) {
        if (mounted) {
          ToastService.showError('Upload failed: ${e.toString()}');
          setState(() => _isUploading = false);
        }
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_textSubmissionController.text.trim().isEmpty && _uploadedFileUrl == null && (_submission?.fileUrl == null)) {
      ToastService.showWarning('Please provide either text or upload a solution file.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final assignRepo = ref.read(assignmentRepositoryProvider);
      await assignRepo.submitAssignment(
        widget.assignmentId,
        textSubmission: _textSubmissionController.text.trim(),
        fileUrl: _uploadedFileUrl ?? _submission?.fileUrl,
        filePublicId: _uploadedFilePublicId ?? _submission?.filePublicId,
      );

      ToastService.showSuccess('Assignment submitted successfully!');
      ref.read(courseProgressRefreshProvider.notifier).state++;
      _loadAssignment();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildStatusBadge(ThemeData theme) {
    String status = _submission?.status ?? 'NOT_SUBMITTED';
    Color color = Colors.grey;
    IconData icon = Icons.info_outline;
    String label = 'Not Submitted';

    if (_submission != null) {
      if (_submission!.isGraded) {
        status = 'GRADED';
        color = Colors.green;
        icon = Icons.verified;
        label = 'Graded';
      } else if (status == 'REVIEWED') {
        color = Colors.purple;
        icon = Icons.rate_review;
        label = 'Reviewed';
      } else if (status == 'LATE') {
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        label = 'Late Submission';
      } else if (status == 'SUBMITTED') {
        color = Colors.blue;
        icon = Icons.check_circle_outline;
        label = 'Submitted';
      }
    } else if (_assignment?.dueDate != null) {
      final due = DateTime.tryParse(_assignment!.dueDate.toString());
      if (due != null && due.isBefore(DateTime.now())) {
        color = Colors.red;
        icon = Icons.error_outline;
        label = 'Overdue / Missing';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assignment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _assignment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assignment')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ApiAlert(error: _error, onRetry: _loadAssignment),
          ),
        ),
      );
    }

    final a = _assignment!;

    return Scaffold(
      appBar: AppBar(title: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(a.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(theme),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text('Max Score: ${a.maxScore} pts', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (a.startDate != null)
                          Text('Start: ${Formatters.formatDate(a.startDate)}', style: TextStyle(color: theme.hintColor)),
                        if (a.dueDate != null)
                          Text('Due: ${Formatters.formatDate(a.dueDate)}', style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    if (a.description != null && a.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(a.description!, style: const TextStyle(fontSize: 13, height: 1.4)),
                    ],
                    if (a.instructions != null && a.instructions!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(a.instructions!, style: const TextStyle(fontSize: 13, height: 1.4)),
                    ],
                    if (a.supportingFileUrl != null && a.supportingFileUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download Supporting File'),
                        onPressed: () async {
                          final uri = Uri.tryParse(mediaUrl(a.supportingFileUrl));
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            ApiAlert(error: _error),

            // Grade / Review Feedback
            if (_submission != null && _submission!.isGraded) ...[
              Card(
                color: Colors.green.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.green),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.grade, color: Colors.green, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Score: ${_submission!.score ?? 0} / ${a.maxScore} (${_submission!.grade ?? ""})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                        ],
                      ),
                      if (_submission!.feedback != null && _submission!.feedback!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Instructor Feedback:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(_submission!.feedback!, style: const TextStyle(fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submission Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _submission != null ? 'Update Submission' : 'Submit Your Solution',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textSubmissionController,
                      decoration: const InputDecoration(
                        labelText: 'Written Answer / Solution Notes',
                        hintText: 'Enter your answer, explanation, or GitHub repository link...',
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: Text(_selectedFile != null ? 'Replace File' : 'Upload File'),
                          onPressed: _isUploading ? null : _pickAndUploadFile,
                        ),
                        const SizedBox(width: 12),
                        if (_isUploading)
                          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        else if (_selectedFile != null)
                          Expanded(
                            child: Text(
                              _selectedFile!.path.split('/').last,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else if (_submission?.fileUrl != null)
                          const Expanded(
                            child: Text(
                              'Current file attached',
                              style: TextStyle(fontSize: 12, color: Colors.green),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting || _isUploading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_submission != null ? 'Update Submission' : 'Submit Assignment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
