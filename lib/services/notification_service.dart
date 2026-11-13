import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/hymn.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

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

  /// Schedule the weekly reminders: seven lines per time of day, one for each
  /// weekday. Each line is paired with the hymn chosen for it, and the body
  /// shows that hymn's number and title from the app data.
  ///
  /// Call this when the user enables reminders and on every app launch while
  /// they are enabled. Pass the hymn list for the language you want titles in.
  static Future<void> scheduleAll({List<Hymn> hymns = const []}) async {
    await cancelAll(); // clear stale schedules first

    final pool = hymns.where((h) => h.number is int).toList();

    const slots = <_Slot>[
      _Slot(0, 7, 0, _morningLines),
      _Slot(1, 12, 0, _afternoonLines),
      _Slot(2, 19, 0, _eveningLines),
    ];

    for (final slot in slots) {
      for (int day = 0; day < 7; day++) {
        final line = slot.lines[day];
        await _scheduleWeekly(
          id: 200 + slot.index * 10 + day,
          // Index 0 is Sunday, index 6 is Saturday (the seventh day)
          weekday: day == 0 ? DateTime.sunday : day,
          hour: slot.hour,
          minute: slot.minute,
          text: line.text,
          hymnNumber: line.hymn,
          hymn: _findHymn(pool, line.hymn),
        );
      }
    }
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() => _plugin.cancelAll();

  // ── Private ────────────────────────────────────────────────────────────────

  static Hymn? _findHymn(List<Hymn> pool, int number) {
    for (final h in pool) {
      if (h.number == number) return h;
    }
    return null;
  }

  static Future<void> _scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String text,
    required int hymnNumber,
    Hymn? hymn,
  }) async {
    final body = hymn == null
        ? 'Hymn $hymnNumber'
        : 'Hymn $hymnNumber · ${hymn.title}';

    await _plugin.zonedSchedule(
      id,
      text,
      body,
      _nextOccurrence(weekday, hour, minute),
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
      // Repeat every week on this weekday at this time
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: '$hymnNumber',
    );
  }

  /// Next moment that falls on [weekday] (DateTime numbering: Mon=1 … Sun=7)
  /// at [hour]:[minute], today or later.
  static tz.TZDateTime _nextOccurrence(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    t = t.add(Duration(days: (weekday - now.weekday) % 7));
    if (t.isBefore(now)) t = t.add(const Duration(days: 7));
    return t;
  }

}

/// Top-level function required by flutter_local_notifications for background taps.
@pragma('vm:entry-point')
void _backgroundHandler(NotificationResponse details) {
  // Navigation from background is handled by the app's initialRoute logic
  // using the stored payload — nothing extra needed here.
}

/// One reminder line and the hymn it opens.
class _Reminder {
  final String text;
  final int hymn;
  const _Reminder(this.text, this.hymn);
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
  _Reminder("Good morning! Let's fill this beautiful morning with a hymn. ❤️", 51),
  _Reminder("Up and about? Let's start the day with a beautiful song.", 130),
  _Reminder("Here’s a lovely hymn to brighten your morning.", 1),
  _Reminder("Rise and shine! Let's make this morning sweeter with a song. 🎵", 51),
  _Reminder("Good morning! Take a moment to enjoy a song of praise.", 130),
  _Reminder("Morning! Let's give thanks to God through song today.", 1),
  _Reminder("Happy Sabbath! May your morning be full of praise. 🙏", 51),
];

const _afternoonLines = <_Reminder>[
  _Reminder("A song can make an ordinary day special. Let's enjoy a hymn together. ❤️", 1),
  _Reminder("Hello there! Here's a midday hymn to brighten your day. 😊", 51),
  _Reminder("Even in the middle of a busy day, there's always time for a song. 🎶", 130),
  _Reminder("Let's pause from the day's work and enjoy a song.", 1),
  _Reminder("It's noon already! Let's share a moment of praise together.", 51),
  _Reminder("Taking a lunch break? Here's a hymn to keep your heart cheerful.", 130),
  _Reminder("Happy Sabbath! May this midday be full of praise. 🎵", 1),
];

const _eveningLines = <_Reminder>[
  _Reminder("Before you settle in for the night, enjoy a beautiful hymn to end the day. 🌙", 130),
  _Reminder("Hello! Hope your day has been good. Here's a hymn to make your evening even better. 😊", 1),
  _Reminder("Good evening! Here's a lovely hymn to bring peace to your evening. ❤️", 51),
  _Reminder("The day is winding down. Why not take a moment to enjoy a beautiful hymn? 🎶", 130),
  _Reminder("Here's a hymn to help you end your day with a heart full of gratitude. 🙏", 1),
  _Reminder("Good evening! May this song of praise bring joy to your heart tonight.", 51),
  _Reminder("The Sabbath is over. Let’s close it with a song of praise. 🌙", 130),
];