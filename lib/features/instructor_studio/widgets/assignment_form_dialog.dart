import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/assignment_model.dart';
import '../../../models/course_model.dart';
import '../../../models/section_model.dart';

class AssignmentFormDialog extends ConsumerStatefulWidget {
  final List<CourseModel> courses;
  final int? initialCourseId;
  final AssignmentModel? assignment;
  final VoidCallback onSaved;

  const AssignmentFormDialog({
    super.key,
    required this.courses,
    this.initialCourseId,
    this.assignment,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required List<CourseModel> courses,
    int? initialCourseId,
    AssignmentModel? assignment,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AssignmentFormDialog(
        courses: courses,
        initialCourseId: initialCourseId,
        assignment: assignment,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<AssignmentFormDialog> createState() =>
      _AssignmentFormDialogState();
}

class _AssignmentFormDialogState extends ConsumerState<AssignmentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _maxScoreCtrl;

  int? _selectedCourseId;
  int? _selectedSectionId;
  List<SectionModel> _sections = [];
  bool _isLoadingSections = false;

  DateTime? _startDate;
  DateTime? _dueDate;
  late bool _allowResubmission;

  String? _supportingFileUrl;
  String? _supportingFilePublicId;
  String? _pickedFileName;
  bool _isUploadingFile = false;
  bool _isSaving = false;

  bool get isEditMode => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    final a = widget.assignment;
    _titleCtrl = TextEditingController(text: a?.title ?? '');
    _descriptionCtrl = TextEditingController(text: a?.description ?? '');
    _instructionsCtrl = TextEditingController(text: a?.instructions ?? '');
    _maxScoreCtrl = TextEditingController(text: '${a?.maxScore ?? 100}');

    _selectedCourseId = a?.courseId ??
        widget.initialCourseId ??
        (widget.courses.isNotEmpty ? widget.courses.first.courseId : null);
    _selectedSectionId = a?.sectionId;

    _startDate = _parseDateTime(a?.startDate);
    _dueDate = _parseDateTime(a?.dueDate);
    _allowResubmission = a?.allowResubmission ?? true;
    _supportingFileUrl = a?.supportingFileUrl;
    _supportingFilePublicId = a?.supportingFilePublicId;

    if (_selectedCourseId != null) {
      _loadSections(_selectedCourseId!);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _instructionsCtrl.dispose();
    _maxScoreCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  Future<void> _loadSections(int courseId) async {
    setState(() => _isLoadingSections = true);
    try {
      final sections = await ref
          .read(sectionRepositoryProvider)
          .getInstructorSections(courseId: courseId);
      if (mounted && _selectedCourseId == courseId) {
        setState(() {
          _sections = sections;
          if (_selectedSectionId != null &&
              !_sections.any((s) => s.sectionId == _selectedSectionId)) {
            _selectedSectionId = null;
          }
          _isLoadingSections = false;
        });
      }
    } catch (_) {
      if (mounted && _selectedCourseId == courseId) {
        setState(() {
          _sections = [];
          _isLoadingSections = false;
        });
      }
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial =
        (isStart ? _startDate : _dueDate) ?? DateTime.now().add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 23,
      time?.minute ?? 59,
    );

    setState(() {
      if (isStart) {
        _startDate = combined;
      } else {
        _dueDate = combined;
      }
    });
  }

  Future<void> _pickAndUploadSupportingFile() async {
    try {
      final fileResult = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'zip', 'txt', 'png', 'jpg', 'jpeg'],
      );
      if (fileResult == null) return;

      setState(() => _isUploadingFile = true);
      final uploadRepo = ref.read(uploadRepositoryProvider);
      Map<String, String> res;

      if (kIsWeb || fileResult.path == null) {
        final bytes = await fileResult.readAsBytes();
        res = await uploadRepo.uploadAssignmentFileBytes(bytes, fileResult.name);
      } else {
        res = await uploadRepo.uploadAssignmentFile(File(fileResult.path!));
      }

      if (mounted) {
        setState(() {
          _supportingFileUrl = res['url'];
          _supportingFilePublicId = res['publicId'];
          _pickedFileName = fileResult.name;
          _isUploadingFile = false;
        });
        ToastService.showSuccess('Supporting file uploaded');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingFile = false);
        ToastService.showError('Upload failed: $e');
      }
    }
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null) {
      ToastService.showWarning('Please select a course');
      return;
    }

    setState(() => _isSaving = true);

    final parsedScore = double.tryParse(_maxScoreCtrl.text.trim());
    final maxScore = (parsedScore != null && parsedScore > 0) ? parsedScore : 100.0;

    final desc = _descriptionCtrl.text.trim();
    final instr = _instructionsCtrl.text.trim();

    final body = <String, dynamic>{
      if (!isEditMode) 'courseId': _selectedCourseId,
      'sectionId': _selectedSectionId,
      'title': _titleCtrl.text.trim(),
      'description': desc.isEmpty ? null : desc,
      'instructions': instr.isEmpty ? null : instr,
      'startDate': _startDate?.toUtc().toIso8601String(),
      'dueDate': _dueDate?.toUtc().toIso8601String(),
      'maxScore': maxScore,
      'supportingFileUrl': _supportingFileUrl,
      'supportingFilePublicId': _supportingFilePublicId,
      'allowResubmission': _allowResubmission,
    };

    try {
      final repo = ref.read(assignmentRepositoryProvider);
      if (isEditMode) {
        await repo.updateAssignment(widget.assignment!.assignmentId, body);
        ToastService.showSuccess('Assignment updated');
      } else {
        await repo.createAssignment(body);
        ToastService.showSuccess('Assignment created');
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ToastService.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final validCourseId = widget.courses.any((c) => c.courseId == _selectedCourseId)
        ? _selectedCourseId
        : null;
    final validSectionId = _sections.any((s) => s.sectionId == _selectedSectionId)
        ? _selectedSectionId
        : null;

    return AlertDialog(
      title: Text(isEditMode ? 'Edit Assignment' : 'Create Assignment'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  key: ValueKey('assign_course_$validCourseId'),
                  initialValue: validCourseId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Course *',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.courses.map((c) {
                    return DropdownMenuItem<int>(
                      value: c.courseId,
                      child: Text(c.title, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: isEditMode
                      ? null
                      : (val) {
                          setState(() {
                            _selectedCourseId = val;
                            _selectedSectionId = null;
                            _sections = [];
                          });
                          if (val != null) {
                            _loadSections(val);
                          }
                        },
                  validator: (val) => val == null ? 'Please select a course' : null,
                ),
                const SizedBox(height: 12),

                if (_isLoadingSections)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                else if (_sections.isNotEmpty) ...[
                  DropdownButtonFormField<int?>(
                    key: ValueKey('assign_section_${validCourseId}_$validSectionId'),
                    initialValue: validSectionId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Course Section (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('No specific section'),
                      ),
                      ..._sections.map((s) {
                        return DropdownMenuItem<int?>(
                          value: s.sectionId,
                          child: Text(s.title, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedSectionId = val),
                  ),
                  const SizedBox(height: 12),
                ],

                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g. Final Project: Full Stack LMS',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Assignment title is required'
                      : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Brief summary of the assignment goal...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _instructionsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Detailed Instructions',
                    hintText: 'Step-by-step instructions, grading rubric...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event, size: 16),
                        label: Text(
                          _startDate != null
                              ? 'Start: ${Formatters.formatDateTime(_startDate)}'
                              : 'Start Date',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _pickDateTime(isStart: true),
                      ),
                    ),
                    if (_startDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        tooltip: 'Clear Start Date',
                        onPressed: () => setState(() => _startDate = null),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text(
                          _dueDate != null
                              ? 'Due: ${Formatters.formatDateTime(_dueDate)}'
                              : 'Due Date',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _pickDateTime(isStart: false),
                      ),
                    ),
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        tooltip: 'Clear Due Date',
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxScoreCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Score (pts)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0) {
                            return 'Enter > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Allow Resubmit',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: _allowResubmission,
                        onChanged: (v) =>
                            setState(() => _allowResubmission = v ?? true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.attach_file, size: 16),
                      label: Text(
                        _supportingFileUrl != null
                            ? 'Replace File'
                            : 'Attach File',
                      ),
                      onPressed: _isUploadingFile
                          ? null
                          : _pickAndUploadSupportingFile,
                    ),
                    const SizedBox(width: 10),
                    if (_isUploadingFile)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_pickedFileName != null)
                      Expanded(
                        child: Text(
                          _pickedFileName!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      )
                    else if (_supportingFileUrl != null &&
                        _supportingFileUrl!.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.download, size: 14),
                        label: const Text(
                          'Current File',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final uri = Uri.tryParse(mediaUrl(_supportingFileUrl));
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isSaving || _isUploadingFile) ? null : _saveAssignment,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEditMode ? 'Update Assignment' : 'Create Assignment'),
        ),
      ],
    );
  }
}
