import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/models.dart';

/// Daily local reminders, one per habit that has a time set. Scheduled on the
/// phone with exact-enough alarms; nothing is sent from a server. The web
/// demo has no scheduled notifications, so this does nothing there.
class Reminders {
  Reminders({FlutterLocalNotificationsPlugin? plugin}) : _n = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _n;
  bool _ready = false;

  static bool get platformSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> init() async {
    if (!platformSupported || _ready) return;
    try {
      tzdata.initializeTimeZones();
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
      await _n.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_stat_pulse')),
      );
      _ready = true;
    } catch (e) {
      debugPrint('reminders: $e');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _n.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Asks for the notification permission (Android 13+). True if allowed.
  Future<bool> requestPermission() async {
    if (!platformSupported) return false;
    await init();
    return await _android?.requestNotificationsPermission() ?? false;
  }

  Future<bool> enabled() async {
    if (!platformSupported) return false;
    await init();
    return await _android?.areNotificationsEnabled() ?? false;
  }

  static int _idFor(String habitId) => habitId.hashCode & 0x7fffffff;

  /// Replaces every scheduled reminder with one per habit that wants one.
  Future<void> sync(List<Habit> habits) async {
    if (!platformSupported) return;
    await init();
    if (!_ready) return;
    try {
      await _n.cancelAll();
      for (final h in habits) {
        final m = h.reminder;
        if (m == null) continue;
        await _n.zonedSchedule(
          id: _idFor(h.id),
          title: h.name,
          body: 'Keep the streak going. Tap to tick it off.',
          scheduledDate: next(tz.TZDateTime.now(tz.local), m),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'reminders',
              'Habit reminders',
              channelDescription: 'A nudge at the time you pick for each habit',
              importance: Importance.high,
              priority: Priority.high,
              color: Color(0xFFFF5A36),
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: h.id,
        );
      }
    } catch (e) {
      debugPrint('reminders: $e');
    }
  }

  /// The next time the clock reads [minutes] after midnight, after [now].
  static tz.TZDateTime next(tz.TZDateTime now, int minutes) {
    var t = tz.TZDateTime(now.location, now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    return t;
  }
}
