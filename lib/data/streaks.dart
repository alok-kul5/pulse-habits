import 'days.dart';
import 'models.dart';

/// Streak rules, the same for one habit, for "perfect days" and for weeks:
///
/// * A run counts done periods in a row.
/// * Periods with nothing scheduled are skipped. They neither add nor break.
/// * Doing it on an unscheduled day still counts, as a bonus.
/// * The current period is never a miss while it is still going: an unticked
///   today leaves yesterday's streak alive until the day is over.
class Streak {
  const Streak({required this.current, required this.best});

  final int current;
  final int best;

  static const none = Streak(current: 0, best: 0);

  /// Generic streak over periods `start..now` (inclusive).
  static Streak over({
    required int start,
    required int now,
    required bool Function(int p) done,
    required bool Function(int p) scheduled,
  }) {
    if (now < start) return none;

    var best = 0, run = 0;
    for (var p = start; p <= now; p++) {
      if (done(p)) {
        run++;
        if (run > best) best = run;
      } else if (scheduled(p) && p != now) {
        run = 0;
      }
    }

    var current = 0;
    for (var p = now; p >= start; p--) {
      if (done(p)) {
        current++;
      } else if (scheduled(p) && p != now) {
        break;
      }
    }
    return Streak(current: current, best: best);
  }

  /// One habit, in days.
  static Streak ofHabit(Habit h, Set<int> done, int today) =>
      over(start: h.createdDay, now: today, done: done.contains, scheduled: h.scheduledOn);

  /// Days on which every scheduled habit was done.
  static Streak perfectDays(List<Habit> habits, Map<String, Set<int>> done, int today) {
    if (habits.isEmpty) return none;
    final start = habits.map((h) => h.createdDay).reduce((a, b) => a < b ? a : b);
    bool scheduled(int d) => habits.any((h) => h.scheduledOn(d));
    bool perfect(int d) {
      var any = false;
      for (final h in habits) {
        if (!h.scheduledOn(d)) continue;
        any = true;
        if (!(done[h.id]?.contains(d) ?? false)) return false;
      }
      return any;
    }

    return over(start: start, now: today, done: perfect, scheduled: scheduled);
  }

  /// Workouts, in weeks: a week counts once it has [goal] sessions.
  /// Every week is scheduled, so an empty past week breaks the run.
  static Streak workoutWeeks(List<Workout> workouts, int goal, int today) {
    if (workouts.isEmpty || goal <= 0) return none;
    final perWeek = <int, int>{};
    for (final w in workouts) {
      final wk = Days.weekStart(w.day) ~/ 7;
      perWeek[wk] = (perWeek[wk] ?? 0) + 1;
    }
    final first = perWeek.keys.reduce((a, b) => a < b ? a : b);
    final now = Days.weekStart(today) ~/ 7;
    return over(start: first, now: now, done: (w) => (perWeek[w] ?? 0) >= goal, scheduled: (_) => true);
  }
}
