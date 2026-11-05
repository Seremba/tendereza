import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'data/hymn_repository.dart';
import 'providers/providers.dart';
import 'screens/hymn_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;

  final prefs = await SharedPreferences.getInstance();

  // ── One-time migration ──
  const migrationKey = 'migration_v1_lg_default';
  if (!prefs.containsKey(migrationKey)) {
    await prefs.remove('language');
    await prefs.setBool(migrationKey, true);
  }

  // ── Notifications ──
  await NotificationService.init(
    onTap: (payload) {
      // Called when user taps a notification while app is running
      _navigateToHymn(payload);
    },
  );

  // One-time reset: everyone starts on the Light theme after this update
  // (Dark was retired). Any theme chosen afterwards is kept as normal.
  const themeResetKey = 'migration_v2_light_theme_reset';
  if (!prefs.containsKey(themeResetKey)) {
    await prefs.remove('app_theme');
    await prefs.setBool(themeResetKey, true);
  }

  // Reschedule daily notifications on every launch (keeps hymn numbers fresh)
  final notificationsEnabled =
      prefs.getBool('notifications_enabled') ?? false;
  if (notificationsEnabled) {
    try {
      final lang = prefs.getString('language') ?? 'lg';
      final hymns = lang == 'en'
          ? await HymnRepository.loadEnglish()
          : await HymnRepository.loadLuganda();
      await NotificationService.scheduleAll(hymns: hymns);
    } catch (_) {
      // A scheduling problem must never stop the app from opening
    }
  }

  // Check if app was launched by tapping a notification (terminated state)
  final launchDetails = await FlutterLocalNotificationsPlugin()
      .getNotificationAppLaunchDetails();
  final launchPayload =
      launchDetails?.didNotificationLaunchApp == true
          ? launchDetails?.notificationResponse?.payload
          : null;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: SdaHymnalApp(initialHymnNumber: launchPayload != null
          ? int.tryParse(launchPayload)
          : null),
    ),
  );
}

/// Navigate to a hymn screen from a notification tap.
/// Works when the app is already running (foreground / background).
void _navigateToHymn(String? payload) {
  if (payload == null) return;
  final number = int.tryParse(payload);
  if (number == null) return;
  final context = navigatorKey.currentContext;
  if (context == null) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => HymnScreen(hymnNumber: number)),
  );
}