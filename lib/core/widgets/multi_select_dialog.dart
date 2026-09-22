import 'package:flutter/material.dart';

class MultiSelectItem<T> {
  final T value;
  final String label;

  MultiSelectItem({required this.value, required this.label});
}

class MultiSelectDialog<T> extends StatefulWidget {
  final String title;
  final List<MultiSelectItem<T>> items;
  final List<T> initialSelectedValues;

  const MultiSelectDialog({
    super.key,
    required this.title,
    required this.items,
    this.initialSelectedValues = const [],
  });

  static Future<List<T>?> show<T>(
    BuildContext context, {
    required String title,
    required List<MultiSelectItem<T>> items,
    List<T> initialSelectedValues = const [],
  }) {
    return showDialog<List<T>>(
      context: context,
      builder: (context) => MultiSelectDialog<T>(
        title: title,
        items: items,
        initialSelectedValues: initialSelectedValues,
      ),
    );
  }

  @override
  State<MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<MultiSelectDialog<T>> {
  late Set<T> _selected;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.from(widget.initialSelectedValues);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((item) => item.label.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No items found'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isChecked = _selected.contains(item.value);
                        return CheckboxListTile(
                          dense: true,
                          title: Text(item.label),
                          value: isChecked,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selected.add(item.value);
                              } else {
                                _selected.remove(item.value);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selected.toList()),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
