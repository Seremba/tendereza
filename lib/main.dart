import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font fetching — all fonts are bundled locally
  GoogleFonts.config.allowRuntimeFetching = false;

  final prefs = await SharedPreferences.getInstance();

  // One-time migration: clear stale 'en' default so 'lg' takes effect
  // on devices that launched the app before this was set.
  // Safe to remove after next Play Store release.
  const migrationKey = 'migration_v1_lg_default';
  if (!prefs.containsKey(migrationKey)) {
    await prefs.remove('language');
    await prefs.setBool(migrationKey, true);
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SdaHymnalApp(),
    ),
  );
}