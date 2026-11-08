import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/hymn.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static final _random = Random();

  // Stable IDs — one per daily slot so rescheduling replaces the old one
  static const _morningId   = 100;
  static const _afternoonId = 101;
  static const _eveningId   = 102;

  // Channel
  static const _channelId   = 'tendereza_daily_hymns_v2';
  static const _channelName = 'Daily Hymns';
  static const _channelDesc =
      'Morning, afternoon and evening hymn reminders';

  /// Call once in main() before runApp.
  static Future<void> init({
    required void Function(String? payload) onTap,
  }) async {
    tz_data.initializeTimeZones();
    // Uganda is East Africa Time (UTC+3)
    tz.setLocalLocation(tz.getLocation('Africa/Kampala'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (details) => onTap(details.payload),
      // Handle taps when app was terminated
      onDidReceiveBackgroundNotificationResponse: _backgroundHandler,
    );

    // Remove the earlier, lower-importance channel (importance can't be
    // changed once a channel exists, so a new channel id is used instead).
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.deleteNotificationChannel('tendereza_daily_hymns');
  }

  /// Request POST_NOTIFICATIONS permission (Android 13+).
  /// Returns true if granted.
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  /// Schedule the three daily notifications, each with a random hymn.
  /// Reads like: "Take a break with Hymn 2: Ka Tukusuute".
  ///
  /// Call this when the user enables reminders AND on every app launch while
  /// they are enabled, so the random hymns are refreshed. Pass the hymn list
  /// for the language you want the titles in.
  static Future<void> scheduleAll({List<Hymn> hymns = const []}) async {
    await cancelAll(); // clear stale schedules first

    // Regular hymns only (1–250), so a reminder always opens a real hymn
    final pool = hymns.where((h) => h.number is int).toList();

    await _schedule(id: _morningId,   hour: 7,  minute: 0,
        title: 'Morning Hymn', lead: 'Start your day with', pool: pool);
    await _schedule(id: _afternoonId, hour: 12, minute: 0,
        title: 'Midday Hymn',  lead: 'Take a break with',   pool: pool);
    await _schedule(id: _eveningId,   hour: 19, minute: 0,
        title: 'Evening Hymn', lead: 'End your day with',   pool: pool);
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() => _plugin.cancelAll();

  // ── Private ────────────────────────────────────────────────────────────────

  static Future<void> _schedule({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String lead,
    required List<Hymn> pool,
  }) async {
    // Pick a random hymn (falls back to a bare number if the list is empty)
    final Hymn? hymn =
        pool.isEmpty ? null : pool[_random.nextInt(pool.length)];
    final number = hymn?.number ?? (_random.nextInt(250) + 1);
    final text = hymn == null
        ? '$lead Hymn $number'
        : '$lead Hymn $number: ${hymn.title}';

    await _plugin.zonedSchedule(
      id,
      title,
      text,
      _nextTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Inexact is plenty for a daily hymn reminder and needs no special
      // exact-alarm permission (which Android 14+ denies by default).
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '$number',
    );
  }

  static tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }
}

/// Top-level function required by flutter_local_notifications for background taps.
@pragma('vm:entry-point')
void _backgroundHandler(NotificationResponse details) {
  // Navigation from background is handled by the app's initialRoute logic
  // using the stored payload — nothing extra needed here.
}