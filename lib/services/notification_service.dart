import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/hymn.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static final _rng = Random();

  // Reminders are scheduled this many days ahead. The schedule is rebuilt
  // at most once a day, and the date of the last rebuild is stored here.
  static const _windowDays = 60;
  static const _builtKey = 'reminders_built_on';

  static const _channelId = 'tendereza_daily_hymns_v2';
  static const _channelName = 'Daily Hymns';
  static const _channelDesc = 'Morning, afternoon and evening hymn reminders';

  /// Call once in main() before runApp.
  static Future<void> init({
    required void Function(String? payload) onTap,
  }) async {
    tz_data.initializeTimeZones();
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
      onDidReceiveBackgroundNotificationResponse: _backgroundHandler,
    );

    // Remove the earlier, lower-importance channel
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.deleteNotificationChannel('tendereza_daily_hymns');
  }

  /// Request POST_NOTIFICATIONS permission (Android 13+). Returns true if granted.
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() => _plugin.cancelAll();

  /// Schedules reminders for the next 60 days. Each reminder uses the wording
  /// for its weekday and a random hymn from [hymns]. No hymn repeats back to back.
  ///
  /// Rebuilt at most once a day. Pass [force] as true when the user turns
  /// reminders on, so the schedule is built straight away.
  static Future<void> scheduleAll({
    required List<Hymn> hymns,
    required SharedPreferences prefs,
    bool force = false,
  }) async {
    final today = _dateKey(DateTime.now());
    if (!force && prefs.getString(_builtKey) == today) return;

    await cancelAll();

    final pool = hymns.where((h) => h.number is int).toList();
    if (pool.isEmpty) return;

    const slots = <_Slot>[
      _Slot(0, 7, 0, _morningLines),
      _Slot(1, 12, 0, _afternoonLines),
      _Slot(2, 19, 0, _eveningLines),
    ];

    final now = tz.TZDateTime.now(tz.local);
    int? previous;

    for (int dayOffset = 0; dayOffset < _windowDays; dayOffset++) {
      for (final slot in slots) {
        final when = tz.TZDateTime(tz.local, now.year, now.month,
            now.day + dayOffset, slot.hour, slot.minute);
        if (!when.isAfter(now)) continue;

        // DateTime weekday runs Mon=1 … Sun=7. Index 0 is Sunday, 6 is Saturday.
        final line = slot.lines[when.weekday % 7];
        final hymn = _pickHymn(pool, previous);
        previous = hymn.number as int;

        await _plugin.zonedSchedule(
          1000 + dayOffset * 10 + slot.index,
          line.text,
          'Hymn ${hymn.number} · ${hymn.title}',
          when,
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
          // Inexact timing needs no exact-alarm permission. A few minutes' delay is fine.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: '${hymn.number}',
        );
      }
    }

    await prefs.setString(_builtKey, today);
  }

  // ── Private ────────────────────────────────────────────────────────────

  static Hymn _pickHymn(List<Hymn> pool, int? previous) {
    final options = previous == null
        ? pool
        : pool.where((h) => h.number != previous).toList();
    return options[_rng.nextInt(options.length)];
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

/// Top-level function required by flutter_local_notifications for background taps.
@pragma('vm:entry-point')
void _backgroundHandler(NotificationResponse details) {
  // Navigation from background is handled by the app's initialRoute logic
  // using the stored payload — nothing extra needed here.
}

/// One reminder line. The hymn is chosen at random when the schedule is built.
class _Reminder {
  final String text;
  const _Reminder(this.text);
}

/// One time of day, with its seven lines (index 0 = Sunday, 6 = Saturday).
class _Slot {
  final int index;
  final int hour;
  final int minute;
  final List<_Reminder> lines;
  const _Slot(this.index, this.hour, this.minute, this.lines);
}

const _morningLines = <_Reminder>[
  _Reminder("Good morning! Let's sing a hymn together. ❤️"),
  _Reminder("Up and about? Let's start with a song."),
  _Reminder("Here's a lovely hymn for your morning."),
  _Reminder("Rise and shine! Let's sing together. 🎵"),
  _Reminder("Good morning! Take a moment to praise."),
  _Reminder("Morning! Let's give thanks in song."),
  _Reminder("Happy Sabbath! Sing a hymn of praise. 🙏"),
];

const _afternoonLines = <_Reminder>[
  _Reminder("A song makes an ordinary day special. ❤️"),
  _Reminder("Hello there! Here's a midday hymn. 😊"),
  _Reminder("Busy day? There's always time to sing. 🎶"),
  _Reminder("Let's pause from work for a song."),
  _Reminder("It's noon! Let's share some praise."),
  _Reminder("Lunch break? Here's a hymn to cheer you."),
  _Reminder("Happy Sabbath! Sing a hymn of praise. 🎵"),
];

const _eveningLines = <_Reminder>[
  _Reminder("A hymn is a lovely end to the day. 🌙"),
  _Reminder("Hello! Here's a hymn for your evening."),
  _Reminder("Good evening! A hymn to bring peace. ❤️"),
  _Reminder("Winding down? Enjoy a hymn with me."),
  _Reminder("Let's end your day with gratitude. 🙏"),
  _Reminder("Good evening! A song of praise tonight."),
  _Reminder("The Sabbath is over. Let’s close with praise. 🌙"),
];