import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static final _random = Random();

  // Stable IDs — one per daily slot so rescheduling replaces the old one
  static const _morningId   = 100;
  static const _afternoonId = 101;
  static const _eveningId   = 102;

  // Channel
  static const _channelId   = 'tendereza_daily_hymns';
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
  }

  /// Request POST_NOTIFICATIONS permission (Android 13+).
  /// Returns true if granted.
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  /// Schedule all three daily notifications with a fresh random hymn each.
  /// Call this when the user enables notifications AND on every app launch
  /// when notifications are enabled (to refresh the random hymn selection).
  static Future<void> scheduleAll() async {
    await cancelAll(); // clear stale schedules first
    await _schedule(id: _morningId,   hour: 7,  minute: 0,
        title: '🌅 Morning Hymn',
        body: 'Start your day with a hymn of praise');
    await _schedule(id: _afternoonId, hour: 12, minute: 0,
        title: '☀️ Midday Hymn',
        body: 'A moment of worship in the middle of your day');
    await _schedule(id: _eveningId,   hour: 19, minute: 0,
        title: '🌙 Evening Hymn',
        body: 'Close your day in song and gratitude');
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() => _plugin.cancelAll();

  // ── Private ────────────────────────────────────────────────────────────────

  static Future<void> _schedule({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    // Pick a random hymn number 1–250
    final hymnNumber = _random.nextInt(250) + 1;

    await _plugin.zonedSchedule(
      id,
      title,
      '$body — Hymn $hymnNumber',
      _nextTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
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
      payload: '$hymnNumber',
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