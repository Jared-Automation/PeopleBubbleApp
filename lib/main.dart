import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/app.dart';

void main() {
  // ProviderScope holds the state of every Riverpod provider in the app.
  runApp(const ProviderScope(child: PeopleBubbleApp()));
}
