import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../list/add_sheet.dart';
import 'backup_ui.dart';

/// What both main screens show before anyone has been added: a short
/// explanation, "Add your first person", and "Import a backup" for a new
/// phone.
class EmptyGraphState extends ConsumerWidget {
  const EmptyGraphState({super.key, required this.hint});

  /// One line on how this screen works, e.g. "Long-press a bubble…".
  final String hint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bubble_chart_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('No one here yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add the people you care about, then what they love, like '
              'and dislike. $hint',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => showAddSheet(context, parentId: null),
              icon: const Icon(Icons.person_add),
              label: const Text('Add your first person'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => importBackup(context, ref),
              icon: const Icon(Icons.file_open_outlined),
              label: const Text('Import a backup'),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Text(
                'Debug: the bug menu has sample data.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
