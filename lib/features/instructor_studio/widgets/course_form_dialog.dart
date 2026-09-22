import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/multi_select_dialog.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/category_model.dart';
import '../../../models/course_model.dart';

class CourseFormDialog extends ConsumerStatefulWidget {
  final CourseModel? course;
  final VoidCallback onSaved;

  const CourseFormDialog({
    super.key,
    this.course,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    CourseModel? course,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CourseFormDialog(
        course: course,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends ConsumerState<CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _outcomesCtrl;
  late final TextEditingController _requirementsCtrl;

  late List<int> _selectedCategoryIds;
  late String _level;
  late String _status;
  late String _coverUrl;
  late String _coverPublicId;

  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  bool _isUploadingCover = false;
  bool _isSaving = false;
  String? _uploadError;

  bool get isEditMode => widget.course != null;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _titleCtrl = TextEditingController(text: c?.title ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _priceCtrl = TextEditingController(text: c != null ? c.price.toString() : '0');
    _durationCtrl = TextEditingController(text: c?.overallDuration ?? '');
    _outcomesCtrl = TextEditingController(text: c?.learningOutcomes ?? '');
    _requirementsCtrl = TextEditingController(text: c?.requirements ?? '');

    _selectedCategoryIds = List<int>.from(c?.categoryIds ?? []);
    _level = c?.level ?? 'ALL_LEVELS';
    _status = c?.status ?? 'PUBLISHED';
    _coverUrl = c?.coverUrl ?? '';
    _coverPublicId = c?.coverPublicId ?? '';

    _loadCategories();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _outcomesCtrl.dispose();
    _requirementsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ref.read(categoryRepositoryProvider).getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  Future<void> _pickAndUploadCover() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _isUploadingCover = true;
        _uploadError = null;
      });

      final bytes = await picked.readAsBytes();
      final uploadRepo = ref.read(uploadRepositoryProvider);
      final result = await uploadRepo.uploadCourseCoverBytes(bytes, picked.name);

      if (mounted) {
        setState(() {
          _coverUrl = result.url;
          _coverPublicId = result.publicId;
          _isUploadingCover = false;
        });
        ToastService.showSuccess('Cover image uploaded to Cloudinary');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = e.toString();
          _isUploadingCover = false;
        });
        ToastService.showError('Cover upload failed: $e');
      }
    }
  }

  Future<void> _openCategorySelector() async {
    if (_categories.isEmpty) return;

    final items = _categories
        .map((c) => MultiSelectItem<int>(
              value: c.categoryId,
              label: c.category,
            ))
        .toList();

    final selected = await MultiSelectDialog.show<int>(
      context,
      title: 'Select Categories',
      items: items,
      initialSelectedValues: _selectedCategoryIds,
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedCategoryIds = selected;
      });
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingCover) {
      ToastService.showInfo('Please wait for image upload to finish');
      return;
    }

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': num.tryParse(_priceCtrl.text.trim()) ?? 0,
      'overallDuration': _durationCtrl.text.trim(),
      'coverUrl': _coverUrl,
      'coverPublicId': _coverPublicId,
      'categoryId': _selectedCategoryIds,
      'level': _level,
      'status': _status,
      'learningOutcomes': _outcomesCtrl.text.trim(),
      'requirements': _requirementsCtrl.text.trim(),
      'instructor': null,
    };

    try {
      final courseRepo = ref.read(courseRepositoryProvider);
      if (isEditMode) {
        await courseRepo.updateInstructorCourse(widget.course!.courseId, payload);
        ToastService.showSuccess('Course updated successfully');
      } else {
        await courseRepo.createInstructorCourse(payload);
        ToastService.showSuccess('Course created successfully');
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
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditMode ? 'Edit Course' : 'Create Course',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: (_isSaving || _isUploadingCover)
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Form fields
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Course Title
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'e.g. Master Spring Boot & Cloud APIs',
                          prefixIcon: Icon(Icons.title, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Description
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Comprehensive description of what this course covers...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Description is required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Price and Duration
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Price (USD) *',
                                hintText: '0 for free',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Price is required';
                                final numVal = num.tryParse(v.trim());
                                if (numVal == null || numVal < 0) return 'Invalid price';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _durationCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Duration',
                                hintText: 'e.g. 4 Weeks or 12h 30m',
                                prefixIcon: Icon(Icons.access_time, size: 20),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Categories MultiSelect
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Categories', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              TextButton.icon(
                                onPressed: _isLoadingCategories ? null : _openCategorySelector,
                                icon: const Icon(Icons.category_outlined, size: 16),
                                label: const Text('Select Categories', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          if (_selectedCategoryIds.isEmpty)
                            GestureDetector(
                              onTap: _isLoadingCategories ? null : _openCategorySelector,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.colorScheme.outlineVariant),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _isLoadingCategories ? 'Loading categories...' : 'No categories selected. Click to choose.',
                                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _selectedCategoryIds.map((id) {
                                final cat = _categories.cast<CategoryModel?>().firstWhere(
                                      (c) => c?.categoryId == id,
                                      orElse: () => null,
                                    );
                                final name = cat?.category ?? 'Category #$id';
                                return Chip(
                                  label: Text(name, style: const TextStyle(fontSize: 12)),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () {
                                    setState(() => _selectedCategoryIds.remove(id));
                                  },
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Level and Status
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _level,
                              decoration: const InputDecoration(
                                labelText: 'Level',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'ALL_LEVELS', child: Text('All Levels')),
                                DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
                                DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate')),
                                DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _level = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'PUBLISHED', child: Text('Published')),
                                DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                                DropdownMenuItem(value: 'ARCHIVED', child: Text('Archived')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _status = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Learning Outcomes
                      TextFormField(
                        controller: _outcomesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Learning Outcomes',
                          hintText: 'What students will learn (e.g. Master Spring Boot, REST APIs)...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Requirements & Prerequisites
                      TextFormField(
                        controller: _requirementsCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Requirements & Prerequisites',
                          hintText: 'Prerequisites (e.g. Basic Java knowledge)...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Cover Image Section with Cloudinary Upload Indicator
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Course Cover Image',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isUploadingCover ? null : _pickAndUploadCover,
                                icon: _isUploadingCover
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.cloud_upload_outlined, size: 18),
                                label: Text(
                                  _isUploadingCover
                                      ? 'Uploading to Cloudinary...'
                                      : (_coverUrl.isNotEmpty ? 'Replace Cover Image' : 'Upload Cover Image'),
                                ),
                              ),
                              if (_coverUrl.isNotEmpty && !_isUploadingCover) ...[
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _coverUrl = '';
                                      _coverPublicId = '';
                                    });
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  label: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                              ],
                            ],
                          ),

                          if (_isUploadingCover) ...[
                            const SizedBox(height: 8),
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 10),
                                  Text(
                                    'Uploading image to Cloudinary...',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Please wait before submitting form',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_coverUrl.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: mediaUrl(_coverUrl),
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (ctx, _) => Container(
                                      height: 140,
                                      color: Colors.grey[200],
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (ctx, _, __) => Container(
                                      height: 140,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 36, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Cloudinary Cloud Storage',
                                        style: TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (_uploadError != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _uploadError!,
                              style: const TextStyle(color: Colors.red, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: (_isSaving || _isUploadingCover)
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_isSaving || _isUploadingCover) ? null : _saveCourse,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isEditMode ? 'Save Changes' : 'Create Course'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
