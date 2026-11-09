import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/providers.dart';
import '../../services/graph_service.dart';
import 'undo_ui.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _day(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String _two(int n) => n.toString().padLeft(2, '0');

/// Writes a backup file and opens Android's share sheet for it (Drive,
/// email, Files…).
Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final json = await ref.read(graphServiceProvider).exportBackup();
    final now = DateTime.now();
    final name =
        'people-bubble-${now.year}-${_two(now.month)}-${_two(now.day)}.json';
    final file = File('${(await getTemporaryDirectory()).path}/$name');
    await file.writeAsString(json);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'People Bubble backup',
      ),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text("Couldn't export: $e")));
  }
}

/// Picks a backup file, says what's in it, and imports it the way the user
/// chooses (merge or replace). The import is one undo step.
Future<void> importBackup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final service = ref.read(graphServiceProvider);
  final picked = await FilePicker.pickFile(dialogTitle: 'Pick a backup');
  if (picked == null || !context.mounted) return;

  final BackupFile file;
  try {
    file = service.readBackup(await picked.xFile.readAsString());
  } on BackupRejected catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return;
  } on Exception catch (e) {
    messenger.showSnackBar(SnackBar(content: Text("Couldn't read it: $e")));
    return;
  }
  if (!context.mounted) return;

  final replace = await showDialog<bool>(
    context: context,
    builder: (context) => _ImportDialog(name: picked.name, file: file),
  );
  if (replace == null) return;
  try {
    final report = await service.importBackup(file, replace: replace);
    if (context.mounted) showUndoSnackBar(context, ref, report.summary);
  } on GraphRuleException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// "Import people-bubble-2026-11-09.json?" with what it holds. Pops true
/// for Replace, false for Merge, null for Cancel.
class _ImportDialog extends StatelessWidget {
  const _ImportDialog({required this.name, required this.file});

  final String name;
  final BackupFile file;

  @override
  Widget build(BuildContext context) {
    String count(String table, String one, String many) {
      final n = file.count(table);
      return '$n ${n == 1 ? one : many}';
    }

    final customTypes = [
      ...file.dump['node_types'].values,
      ...file.dump['edge_types'].values,
    ].where((t) => t['built_in'] != 1).length;
    final exported = file.exportedAt;
    return AlertDialog(
      title: const Text('Import backup?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            '${count('nodes', 'bubble', 'bubbles')}, '
            '${count('edges', 'line', 'lines')}, '
            '$customTypes custom ${customTypes == 1 ? 'type' : 'types'}'
            '${exported == null ? '' : ', saved ${_day(exported)}'}.',
          ),
          if (file.badRows > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${file.badRows} damaged '
              '${file.badRows == 1 ? 'entry' : 'entries'} will be skipped.',
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Merge adds what’s new and keeps the newer version of anything '
            'on both. Replace swaps everything here for the backup. '
            'Either can be undone.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Replace'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Merge'),
        ),
      ],
    );
  }
}
