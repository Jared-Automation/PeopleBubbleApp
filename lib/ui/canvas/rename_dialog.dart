import 'package:flutter/material.dart';

/// Asks for a new name. Returns the text, or null if cancelled.
/// [allowEmpty] lets a line label be cleared.
Future<String?> showRenameDialog(
  BuildContext context, {
  required String title,
  required String initial,
  String label = 'Name',
  bool allowEmpty = false,
}) => showDialog<String>(
  context: context,
  builder: (context) =>
      _RenameDialog(title, initial, label: label, allowEmpty: allowEmpty),
);

class _RenameDialog extends StatefulWidget {
  const _RenameDialog(
    this.title,
    this.initial, {
    required this.label,
    required this.allowEmpty,
  });

  final String title;
  final String initial;
  final String label;
  final bool allowEmpty;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _text = TextEditingController(text: widget.initial)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initial.length,
    );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSave => widget.allowEmpty || _text.text.trim().isNotEmpty;

  void _save() {
    if (_canSave) Navigator.pop(context, _text.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _text,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: widget.label),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _save(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _canSave ? _save : null,
        child: const Text('Save'),
      ),
    ],
  );
}
