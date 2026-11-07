import 'package:flutter/material.dart';

import 'canvas/canvas_screen.dart';
import 'list/list_screen.dart';

/// Bottom navigation between the two views of the same data.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // The canvas is the main view; the list is one tap away.
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps both views alive so each keeps its scroll/zoom.
      body: IndexedStack(
        index: _index,
        children: const [ListScreen(), CanvasScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'List'),
          NavigationDestination(
            icon: Icon(Icons.bubble_chart),
            label: 'Bubbles',
          ),
        ],
      ),
    );
  }
}
