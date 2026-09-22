import 'package:flutter/material.dart';

class DropdownOption<T> {
  final T value;
  final String label;

  DropdownOption({required this.value, required this.label});
}

class SelectFetchDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final Future<List<DropdownOption<T>>> Function() fetchOptions;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final String? placeholder;

  const SelectFetchDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.fetchOptions,
    required this.onChanged,
    this.validator,
    this.placeholder,
  });

  @override
  State<SelectFetchDropdown<T>> createState() => _SelectFetchDropdownState<T>();
}

class _SelectFetchDropdownState<T> extends State<SelectFetchDropdown<T>> {
  List<DropdownOption<T>> _options = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final opts = await widget.fetchOptions();
      if (mounted) {
        setState(() {
          _options = opts;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            isDense: true,
          ),
          child: const SizedBox(
            height: 20,
            child: LinearProgressIndicator(),
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            isDense: true,
            errorText: 'Failed to load options',
          ),
          child: Text(_error!, style: const TextStyle(fontSize: 12)),
        ),
      );
    }

    // Ensure selected value is valid in options
    final hasValidValue = widget.value != null &&
        _options.any((opt) => opt.value == widget.value);

    return DropdownButtonFormField<T>(
      initialValue: hasValidValue ? widget.value : null,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.placeholder ?? 'Select ${widget.label}',
        isDense: true,
      ),
      items: _options.map((opt) {
        return DropdownMenuItem<T>(
          value: opt.value,
          child: Text(opt.label, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: widget.onChanged,
      validator: widget.validator,
    );
  }
}
