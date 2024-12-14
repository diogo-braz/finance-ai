import 'package:finance_ai/config/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'main.dart';

/// Staging config entry point.
/// Launch with `flutter run --target lib/main_staging.dart`.
/// Uses remote data from a server.
void main() async {
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: providersRemote,
      child: const MainApp(),
    ),
  );
}
