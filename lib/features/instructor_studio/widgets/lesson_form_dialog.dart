import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/lesson_model.dart';

class LessonFormDialog extends ConsumerStatefulWidget {
  final int sectionId;
  final int courseId;
  final LessonModel? lesson;
  final VoidCallback onSaved;

  const LessonFormDialog({
    super.key,
    required this.sectionId,
    required this.courseId,
    this.lesson,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required int sectionId,
    required int courseId,
    LessonModel? lesson,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LessonFormDialog(
        sectionId: sectionId,
        courseId: courseId,
        lesson: lesson,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<LessonFormDialog> createState() => _LessonFormDialogState();
}

class _LessonFormDialogState extends ConsumerState<LessonFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _orderIndexCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _textContentCtrl;

  late String _videoUrl;
  late String _videoPublicId;
  late bool _isFree;

  bool _isUploadingVideo = false;
  double _uploadProgress = 0.0;
  bool _isSaving = false;
  String? _uploadError;

  bool get isEditMode => widget.lesson != null;

  @override
  void initState() {
    super.initState();
    final l = widget.lesson;
    _titleCtrl = TextEditingController(text: l?.title ?? '');
    _orderIndexCtrl = TextEditingController(text: (l?.orderIndex ?? 0).toString());
    _durationCtrl = TextEditingController(text: l?.duration ?? '');
    _descriptionCtrl = TextEditingController(text: l?.description ?? '');
    _textContentCtrl = TextEditingController(text: l?.textContent ?? '');

    _videoUrl = l?.videoUrl ?? l?.videoDir ?? '';
    _videoPublicId = l?.videoPublicId ?? '';
    _isFree = l?.isFree ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _orderIndexCtrl.dispose();
    _durationCtrl.dispose();
    _descriptionCtrl.dispose();
    _textContentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() {
        _isUploadingVideo = true;
        _uploadProgress = 0.0;
        _uploadError = null;
      });

      final bytes = await picked.readAsBytes();
      final uploadRepo = ref.read(uploadRepositoryProvider);
      final res = await uploadRepo.uploadLessonVideoBytes(
        bytes,
        picked.name,
        onSendProgress: (count, total) {
          if (total > 0 && mounted) {
            setState(() {
              _uploadProgress = count / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _videoUrl = res.url;
          _videoPublicId = res.publicId;
          _isUploadingVideo = false;
        });
        ToastService.showSuccess('Video uploaded to Cloudinary');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = e.toString();
          _isUploadingVideo = false;
        });
        ToastService.showError('Video upload failed: $e');
      }
    }
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingVideo) {
      ToastService.showInfo('Please wait for video upload to finish');
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'title': _titleCtrl.text.trim(),
      'videoUrl': _videoUrl,
      'videoPublicId': _videoPublicId,
      'videoDir': _videoUrl,
      'orderIndex': int.tryParse(_orderIndexCtrl.text.trim()) ?? 0,
      'duration': _durationCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'textContent': _textContentCtrl.text.trim(),
      'isFree': _isFree,
      'sectionId': widget.sectionId,
    };

    try {
      final lessonRepo = ref.read(lessonRepositoryProvider);
      if (isEditMode) {
        await lessonRepo.updateInstructorLesson(widget.lesson!.lessonId, payload);
        ToastService.showSuccess('Lesson updated');
      } else {
        await lessonRepo.createInstructorLesson(payload);
        ToastService.showSuccess('Lesson created');
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
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditMode ? 'Edit Lesson' : 'Create Lesson',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: (_isSaving || _isUploadingVideo) ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Form content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'Lesson title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Order Index & Duration
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _orderIndexCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Order Index',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _durationCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Duration',
                                hintText: 'e.g. 15:30',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Video Upload Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Video', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isUploadingVideo ? null : _pickAndUploadVideo,
                                icon: _isUploadingVideo
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.video_file_outlined, size: 18),
                                label: Text(
                                  _isUploadingVideo
                                      ? 'Uploading video to Cloudinary...'
                                      : (_videoUrl.isNotEmpty ? 'Replace Video' : 'Upload Video File'),
                                ),
                              ),
                              if (_videoUrl.isNotEmpty && !_isUploadingVideo) ...[
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _videoUrl = '';
                                      _videoPublicId = '';
                                    });
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  label: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                              ],
                            ],
                          ),

                          if (_isUploadingVideo) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: _uploadProgress > 0 ? _uploadProgress : null),
                            const SizedBox(height: 4),
                            Text(
                              'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}% to Cloudinary',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ] else if (_videoUrl.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _videoUrl,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (_uploadError != null) ...[
                            const SizedBox(height: 4),
                            Text(_uploadError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Description
                      TextFormField(
                        controller: _descriptionCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief description of this lesson',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Reading Text / Notes
                      TextFormField(
                        controller: _textContentCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Reading Text / Notes',
                          hintText: 'Supplemental text, instructions, or notes',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Free Trial / Preview Lesson Checkbox
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(8),
                          color: _isFree ? Colors.green.withValues(alpha: 0.05) : null,
                        ),
                        child: CheckboxListTile(
                          value: _isFree,
                          onChanged: (v) => setState(() => _isFree = v ?? false),
                          title: const Text(
                            'Free Trial / Preview Lesson',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Allow prospective students to watch this video without enrolling in the course.',
                            style: TextStyle(fontSize: 12),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: (_isSaving || _isUploadingVideo) ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_isSaving || _isUploadingVideo) ? null : _saveLesson,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isEditMode ? 'Save Changes' : 'Save'),
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
