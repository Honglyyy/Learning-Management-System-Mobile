import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/section_model.dart';

class SectionFormDialog extends ConsumerStatefulWidget {
  final int courseId;
  final SectionModel? section;
  final VoidCallback onSaved;

  const SectionFormDialog({
    super.key,
    required this.courseId,
    this.section,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required int courseId,
    SectionModel? section,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SectionFormDialog(
        courseId: courseId,
        section: section,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<SectionFormDialog> createState() => _SectionFormDialogState();
}

class _SectionFormDialogState extends ConsumerState<SectionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _durationCtrl;
  bool _isSaving = false;

  bool get isEditMode => widget.section != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.section?.title ?? '');
    _durationCtrl = TextEditingController(text: widget.section?.duration ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      'title': _titleCtrl.text.trim(),
      'duration': _durationCtrl.text.trim(),
      'courseId': widget.courseId,
    };

    try {
      final sectionRepo = ref.read(sectionRepositoryProvider);
      if (isEditMode) {
        await sectionRepo.updateInstructorSection(widget.section!.sectionId, payload);
        ToastService.showSuccess('Section updated');
      } else {
        await sectionRepo.createInstructorSection(payload);
        ToastService.showSuccess('Section created');
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

    return AlertDialog(
      title: Text(isEditMode ? 'Edit Section' : 'Create Section'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g. Introduction to the Course',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Section title is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _durationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  hintText: 'e.g. 45 min',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveSection,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditMode ? 'Save Changes' : 'Save'),
        ),
      ],
    );
  }
}
