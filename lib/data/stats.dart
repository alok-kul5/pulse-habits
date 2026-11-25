import 'dart:math' as math;

import 'days.dart';
import 'models.dart';

/// Pure functions behind the charts and the heatmap. No Flutter, so every
/// number on screen is unit-tested.
abstract final class Stats {
  /// Share of the habits scheduled on [day] that were done, 0…1,
  /// or null when nothing was scheduled.
  static double? dayScore(List<Habit> habits, Map<String, Set<int>> done, int day) {
    var due = 0, hit = 0;
    for (final h in habits) {
      if (!h.scheduledOn(day)) continue;
      due++;
      if (done[h.id]?.contains(day) ?? false) hit++;
    }
    return due == 0 ? null : hit / due;
  }

  /// Heatmap level for a score: 0 (nothing) to 4 (everything).
  /// Null scores (nothing due) are level -1 and drawn as empty cells.
  static int level(double? score) {
    if (score == null) return -1;
    if (score <= 0) return 0;
    if (score < .34) return 1;
    if (score < .67) return 2;
    if (score < 1) return 3;
    return 4;
  }

  /// Levels for the last [weeks] whole weeks up to and including the week of
  /// [today], column by column (Monday first). Days after today are -2.
  static List<List<int>> heatmap(int weeks, int today, double? Function(int day) score) {
    final first = Days.weekStart(today) - (weeks - 1) * 7;
    return [
      for (var w = 0; w < weeks; w++)
        [
          for (var d = 0; d < 7; d++)
            if (first + w * 7 + d > today) -2 else level(score(first + w * 7 + d)),
        ],
    ];
  }

  /// Done ÷ due over `from..to`, counting only scheduled days. Null if none were due.
  static double? completionRate(List<Habit> habits, Map<String, Set<int>> done, int from, int to) {
    var due = 0, hit = 0;
    for (var d = from; d <= to; d++) {
      for (final h in habits) {
        if (!h.scheduledOn(d)) continue;
        due++;
        if (done[h.id]?.contains(d) ?? false) hit++;
      }
    }
    return due == 0 ? null : hit / due;
  }

  /// Completion rate per week for the last [weeks] weeks (oldest first).
  /// The current week only counts days up to today.
  static List<double?> weeklyCompletion(List<Habit> habits, Map<String, Set<int>> done, int weeks, int today) {
    final thisWeek = Days.weekStart(today);
    return [
      for (var i = weeks - 1; i >= 0; i--)
        completionRate(habits, done, thisWeek - i * 7, math.min(thisWeek - i * 7 + 6, today)),
    ];
  }

  /// Completion rate by weekday (Mon…Sun) over the last [days] days.
  static List<double?> byWeekday(Habit h, Set<int> done, int days, int today) {
    final due = List.filled(7, 0), hit = List.filled(7, 0);
    for (var d = today - days + 1; d <= today; d++) {
      if (!h.scheduledOn(d)) continue;
      final i = Days.weekday(d) - 1;
      due[i]++;
      if (done.contains(d)) hit[i]++;
    }
    return [for (var i = 0; i < 7; i++) due[i] == 0 ? null : hit[i] / due[i]];
  }

  /// Strength volume (kg) per week for the last [weeks] weeks, oldest first.
  static List<double> weeklyVolume(List<Workout> workouts, int weeks, int today) =>
      _weekly(workouts, weeks, today, (w) => w.volume);

  /// Training minutes per week, every kind of workout.
  static List<double> weeklyMinutes(List<Workout> workouts, int weeks, int today) =>
      _weekly(workouts, weeks, today, (w) => w.minutes.toDouble());

  static List<int> weeklySessions(List<Workout> workouts, int weeks, int today) =>
      _weekly(workouts, weeks, today, (_) => 1).map((v) => v.round()).toList();

  static List<double> _weekly(List<Workout> workouts, int weeks, int today, double Function(Workout) f) {
    final first = Days.weekStart(today) - (weeks - 1) * 7;
    final out = List<double>.filled(weeks, 0);
    for (final w in workouts) {
      if (w.day < first || w.day > today) continue;
      out[(w.day - first) ~/ 7] += f(w);
    }
    return out;
  }

  /// Daily steps for the last [days] days (oldest first). Missing days are 0.
  static List<int> stepSeries(Map<int, int> steps, int days, int today) => [
    for (var d = today - days + 1; d <= today; d++) steps[d] ?? 0,
  ];

  /// Trailing moving average with a window of [window]. Early points
  /// average over what exists so far.
  static List<double> movingAverage(List<num> xs, int window) {
    final out = <double>[];
    var sum = 0.0;
    for (var i = 0; i < xs.length; i++) {
      sum += xs[i];
      if (i >= window) sum -= xs[i - window];
      out.add(sum / math.min(i + 1, window));
    }
    return out;
  }

  /// Percentage change from the first half of [xs] to the second, or null if
  /// the first half is zero.
  static double? trend(List<num> xs) {
    if (xs.length < 2) return null;
    final h = xs.length ~/ 2;
    final a = xs.take(h).fold<double>(0, (s, v) => s + v) / h;
    final b = xs.skip(xs.length - h).fold<double>(0, (s, v) => s + v) / h;
    if (a == 0) return null;
    return (b - a) / a;
  }
}
