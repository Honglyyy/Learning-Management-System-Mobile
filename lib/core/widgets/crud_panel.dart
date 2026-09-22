import 'package:flutter/material.dart';
import 'api_alert.dart';
import 'confirmation_dialog.dart';
import 'empty_state.dart';
import 'loading_skeleton.dart';
import 'toast_service.dart';

enum CrudFieldType { text, number, textarea, checkbox }

class CrudFieldDef {
  final String name;
  final String label;
  final CrudFieldType type;
  final String? placeholder;
  final bool isRequired;

  CrudFieldDef({
    required this.name,
    required this.label,
    this.type = CrudFieldType.text,
    this.placeholder,
    this.isRequired = true,
  });
}

class CrudColumnDef {
  final String key;
  final String label;
  final Widget Function(Map<String, dynamic> row)? render;

  CrudColumnDef({
    required this.key,
    required this.label,
    this.render,
  });
}

class CrudConfig {
  final String title;
  final String idKey;
  final List<CrudFieldDef> fields;
  final List<CrudColumnDef> columns;
  final Future<List<Map<String, dynamic>>> Function() fetchList;
  final Future<void> Function(Map<String, dynamic> body) createItem;
  final Future<void> Function(dynamic id, Map<String, dynamic> body) updateItem;
  final Future<void> Function(dynamic id) deleteItem;

  CrudConfig({
    required this.title,
    this.idKey = 'id',
    required this.fields,
    required this.columns,
    required this.fetchList,
    required this.createItem,
    required this.updateItem,
    required this.deleteItem,
  });
}

class CrudPanel extends StatefulWidget {
  final CrudConfig config;

  const CrudPanel({super.key, required this.config});

  @override
  State<CrudPanel> createState() => _CrudPanelState();
}

class _CrudPanelState extends State<CrudPanel> {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await widget.config.fetchList();
      if (mounted) {
        setState(() {
          _data = items;
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

  void _openFormDialog({Map<String, dynamic>? initial}) {
    showDialog(
      context: context,
      builder: (context) => _CrudFormDialog(
        config: widget.config,
        initial: initial,
        onSuccess: () {
          _loadData();
        },
      ),
    );
  }

  Future<void> _confirmDelete(dynamic id) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Item',
      message: 'Are you sure you want to delete this record? This action cannot be undone.',
      confirmLabel: 'Delete',
    );

    if (confirmed == true) {
      try {
        await widget.config.deleteItem(id);
        ToastService.showSuccess('Deleted successfully');
        _loadData();
      } catch (e) {
        ToastService.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _data.where((row) {
      if (_searchQuery.isEmpty) return true;
      return row.values.any(
        (val) => val.toString().toLowerCase().contains(_searchQuery.toLowerCase()),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.config.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _loadData,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
                onPressed: () => _openFormDialog(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search records...',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 12),
          ApiAlert(error: _error, onRetry: _loadData),
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, _) => const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: LoadingSkeleton(width: double.infinity, height: 60),
                    ),
                  )
                : filtered.isEmpty
                    ? const EmptyState(
                        title: 'No records found',
                        description: 'Create a new record or adjust your search.',
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final row = filtered[index];
                          final id = row[widget.config.idKey] ?? row['id'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: widget.config.columns.map((col) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                                              child: col.render != null
                                                  ? col.render!(row)
                                                  : Row(
                                                      children: [
                                                        Text(
                                                          '${col.label}: ',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            '${row[col.key] ?? ""}',
                                                            style: const TextStyle(fontSize: 13),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20),
                                            tooltip: 'Edit',
                                            onPressed: () => _openFormDialog(initial: row),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                            tooltip: 'Delete',
                                            onPressed: () => _confirmDelete(id),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CrudFormDialog extends StatefulWidget {
  final CrudConfig config;
  final Map<String, dynamic>? initial;
  final VoidCallback onSuccess;

  const _CrudFormDialog({
    required this.config,
    this.initial,
    required this.onSuccess,
  });

  @override
  State<_CrudFormDialog> createState() => _CrudFormDialogState();
}

class _CrudFormDialogState extends State<_CrudFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _formData;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _formData = widget.initial != null
        ? Map<String, dynamic>.from(widget.initial!)
        : {};
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      if (widget.initial == null) {
        await widget.config.createItem(_formData);
        ToastService.showSuccess('Created successfully');
      } else {
        final id = widget.initial![widget.config.idKey] ?? widget.initial!['id'];
        await widget.config.updateItem(id, _formData);
        ToastService.showSuccess('Updated successfully');
      }
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit ${widget.config.title}' : 'New ${widget.config.title}'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApiAlert(error: _error),
                ...widget.config.fields.map((field) {
                  final initialValue = _formData[field.name]?.toString() ?? '';

                  if (field.type == CrudFieldType.checkbox) {
                    final isChecked = _formData[field.name] == true;
                    return CheckboxListTile(
                      dense: true,
                      title: Text(field.label),
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          _formData[field.name] = val ?? false;
                        });
                      },
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TextFormField(
                      initialValue: initialValue,
                      decoration: InputDecoration(
                        labelText: field.label,
                        hintText: field.placeholder,
                        isDense: true,
                      ),
                      keyboardType: field.type == CrudFieldType.number
                          ? TextInputType.number
                          : field.type == CrudFieldType.textarea
                              ? TextInputType.multiline
                              : TextInputType.text,
                      maxLines: field.type == CrudFieldType.textarea ? 3 : 1,
                      validator: (val) {
                        if (field.isRequired && (val == null || val.trim().isEmpty)) {
                          return '${field.label} is required';
                        }
                        if (field.type == CrudFieldType.number && val != null && val.isNotEmpty) {
                          if (num.tryParse(val) == null) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                      onSaved: (val) {
                        if (field.type == CrudFieldType.number) {
                          _formData[field.name] = num.tryParse(val ?? '') ?? 0;
                        } else {
                          _formData[field.name] = val ?? '';
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditing ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }
}
