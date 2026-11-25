import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../brand/tokens.dart';
import '../data/stats.dart';
import '../state/tracker.dart';

/// Feeds the Android home-screen widget. The widget itself is native Kotlin
/// (`PulseWidget.kt`): it reads these keys and draws today's habits, the
/// perfect-day streak and a seven-week heatmap. Tapping a habit on the
/// widget opens the app with `pulse://tick/<id>` and ticks it there.
class WidgetSync {
  static bool get platformSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const provider = 'PulseWidget';

  /// What the widget shows, as plain data (also used to draw the in-app preview).
  static Map<String, Object> snapshot(Tracker t) {
    final due = t.dueToday;
    final heat = Stats.heatmap(7, t.today, t.dayScore);
    return {
      'done': t.doneToday,
      'due': due.length,
      'streak': t.perfectStreak.current,
      'habits': jsonEncode([
        for (final h in due.take(5))
          {
            'id': h.id,
            'name': h.name,
            'done': t.isDone(h.id, t.today),
            'color': Palette.hue(h.hue).toARGB32(),
            'streak': t.streakOf(h).current,
          },
      ]),
      // 49 characters, week by week, Monday first: 0–4 levels, '-' nothing due, ' ' future.
      'heat': [
        for (final w in heat)
          for (final l in w) l == -2 ? ' ' : (l < 0 ? '-' : '$l'),
      ].join(),
    };
  }

  static Future<void> push(Tracker t) async {
    if (!platformSupported) return;
    try {
      for (final e in snapshot(t).entries) {
        await HomeWidget.saveWidgetData(e.key, e.value);
      }
      await HomeWidget.updateWidget(androidName: provider);
    } catch (e) {
      debugPrint('widget: $e');
    }
  }

  /// Habit ids to tick, from widget taps: the one that launched the app and
  /// any that arrive while it is open.
  static Stream<String> ticks() {
    if (!platformSupported) return const Stream.empty();
    final c = StreamController<String>();
    String? idOf(Uri? u) => (u != null && u.scheme == 'pulse' && u.host == 'tick' && u.pathSegments.isNotEmpty)
        ? u.pathSegments.first
        : null;
    HomeWidget.initiallyLaunchedFromHomeWidget().then((u) {
      final id = idOf(u);
      if (id != null) c.add(id);
    }, onError: (_) {});
    final sub = HomeWidget.widgetClicked.listen((u) {
      final id = idOf(u);
      if (id != null) c.add(id);
    }, onError: (_) {});
    c.onCancel = sub.cancel;
    return c.stream;
  }
}
