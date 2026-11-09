import 'package:flutter/material.dart';

import '../types/types_screen.dart';

/// The ⋮ menu on both main screens: things used now and then, kept off the
/// bottom bar.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      tooltip: 'More',
      onSelected: (open) => open(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const TypesScreen()),
          ),
          child: const ListTile(
            leading: Icon(Icons.category_outlined),
            title: Text('Types'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
