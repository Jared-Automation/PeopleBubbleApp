import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../types/types_screen.dart';
import 'backup_ui.dart';
import 'delete_all.dart';

/// The ⋮ menu on both main screens: things used now and then, kept off the
/// bottom bar.
class AppMenuButton extends ConsumerWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget item(IconData icon, String text) => ListTile(
      leading: Icon(icon),
      title: Text(text),
      contentPadding: EdgeInsets.zero,
    );

    // The callbacks use this widget's context, not the menu's: the menu is
    // gone by the time they run.
    return PopupMenuButton<VoidCallback>(
      tooltip: 'More',
      onSelected: (open) => open(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const TypesScreen()),
          ),
          child: item(Icons.category_outlined, 'Types'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: () => exportBackup(context, ref),
          child: item(Icons.ios_share, 'Export backup'),
        ),
        PopupMenuItem(
          value: () => importBackup(context, ref),
          child: item(Icons.file_open_outlined, 'Import backup'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: () => confirmAndDeleteAll(context, ref),
          child: item(Icons.delete_forever_outlined, 'Delete everything'),
        ),
      ],
    );
  }
}
