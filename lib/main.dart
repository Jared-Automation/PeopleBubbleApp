import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui/app.dart';
import 'ui/list/list_state.dart';

Future<void> main() async {
  // Plugins (like shared_preferences) need the engine binding before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // ProviderScope holds the state of every Riverpod provider in the app.
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PeopleBubbleApp(),
    ),
  );
}
