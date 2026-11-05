import 'package:flutter/material.dart';

import 'home_shell.dart';

class PeopleBubbleApp extends StatelessWidget {
  const PeopleBubbleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'People Bubble',
      theme: ThemeData(colorSchemeSeed: Colors.pink),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.pink,
        brightness: Brightness.dark,
      ),
      home: const HomeShell(),
    );
  }
}
