import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// Placeholder for the collapsible list view (phase 3).
class ListScreen extends ConsumerWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(storedSchemaVersionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: Center(
        child: Text(switch (version) {
          AsyncData(:final value) => 'Database ready (schema v$value)',
          AsyncError(:final error) => 'Database error: $error',
          _ => 'Opening database…',
        }),
      ),
    );
  }
}
