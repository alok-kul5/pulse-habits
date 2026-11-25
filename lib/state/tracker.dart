import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/days.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../data/stats.dart';
import '../data/streaks.dart';

enum StepSource { sample, health }

/// Everything the user has: habits, ticks, workouts and steps. Offline-first:
/// the whole state lives on the device (shared_preferences, localStorage on
/// the web) and is written after every change. There is no server.
class Tracker extends ChangeNotifier {
  Tracker({this.prefs, int Function()? clock, bool seed = true}) : _clock = clock ?? Days.today {
    if (!_load() && seed) _applySample();
  }

  static const storageKey = 'pulse.v1';

  final SharedPreferences? prefs;
  final int Function() _clock;

  int get today => _clock();

  final List<Habit> habits = [];
  final Map<String, Set<int>> done = {};
  final List<Workout> workouts = [];
  Map<int, int> steps = {};
  StepSource stepSource = StepSource.sample;

  /// True while the data is the demo history, not the user's own.
  bool sample = false;

  int weeklyGoal = 3;
  int stepGoal = 8000;

  // Reading ------------------------------------------------------------

  List<Habit> get dueToday => habits.where((h) => h.scheduledOn(today)).toList();

  bool isDone(String id, int day) => done[id]?.contains(day) ?? false;

  int get doneToday => dueToday.where((h) => isDone(h.id, today)).length;

  double get todayProgress {
    final due = dueToday.length;
    return due == 0 ? 0 : doneToday / due;
  }

  Streak streakOf(Habit h) => Streak.ofHabit(h, done[h.id] ?? const {}, today);

  Streak get perfectStreak => Streak.perfectDays(habits, done, today);

  Streak get workoutStreak => Streak.workoutWeeks(workouts, weeklyGoal, today);

  double? dayScore(int day) => Stats.dayScore(habits, done, day);

  int get sessionsThisWeek {
    final from = Days.weekStart(today);
    return workouts.where((w) => w.day >= from && w.day <= today).length;
  }

  List<Workout> get recentWorkouts => [...workouts]..sort((a, b) => b.day.compareTo(a.day));

  Habit? habit(String id) {
    for (final h in habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  // Changing -----------------------------------------------------------

  /// Ticks or unticks a habit for a day. Returns the new state.
  bool toggle(String id, [int? day]) {
    final d = day ?? today;
    final set = done.putIfAbsent(id, () => <int>{});
    final now = !set.remove(d);
    if (now) set.add(d);
    _changed();
    return now;
  }

  String _id(String prefix) => '$prefix${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Habit addHabit({required String name, required String icon, required int hue, Set<int>? weekdays, int? reminder}) {
    final h = Habit(
      id: _id('h'),
      name: name.trim(),
      icon: icon,
      hue: hue,
      createdDay: today,
      weekdays: weekdays,
      reminder: reminder,
    );
    habits.add(h);
    done[h.id] = {};
    _changed();
    return h;
  }

  void updateHabit(Habit h) {
    if (!habits.contains(h)) return;
    _changed();
  }

  /// Removes a habit; returns something to hand back to [restoreHabit] for undo.
  (int, Habit, Set<int>)? removeHabit(String id) {
    final i = habits.indexWhere((h) => h.id == id);
    if (i < 0) return null;
    final h = habits.removeAt(i);
    final d = done.remove(id) ?? {};
    _changed();
    return (i, h, d);
  }

  void restoreHabit((int, Habit, Set<int>) removed) {
    final (i, h, d) = removed;
    habits.insert(i.clamp(0, habits.length), h);
    done[h.id] = d;
    _changed();
  }

  void reorder(int from, int to) {
    if (from < 0 || from >= habits.length) return;
    final h = habits.removeAt(from);
    habits.insert(to.clamp(0, habits.length), h);
    _changed();
  }

  Workout logWorkout({
    required WorkoutKind kind,
    required int minutes,
    List<Lift> lifts = const [],
    double km = 0,
    int? day,
  }) {
    final w = Workout(id: _id('w'), day: day ?? today, kind: kind, minutes: minutes, lifts: lifts, km: km);
    workouts.add(w);
    _changed();
    return w;
  }

  void removeWorkout(String id) {
    workouts.removeWhere((w) => w.id == id);
    _changed();
  }

  void setWeeklyGoal(int g) {
    weeklyGoal = g.clamp(1, 7);
    _changed();
  }

  void setStepGoal(int g) {
    stepGoal = g.clamp(1000, 30000);
    _changed();
  }

  /// Real step counts from Health Connect replace the sample ones.
  void setHealthSteps(Map<int, int> counts) {
    steps = Map.of(counts);
    stepSource = StepSource.health;
    _changed();
  }

  /// Wipes the demo history and keeps nothing.
  void startFresh() {
    habits.clear();
    done.clear();
    workouts.clear();
    if (stepSource == StepSource.sample) steps = {};
    sample = false;
    _changed();
  }

  void loadSample() {
    _applySample();
    _changed();
  }

  void _applySample() {
    final s = SampleData.build(today);
    habits
      ..clear()
      ..addAll(s.habits);
    done
      ..clear()
      ..addAll(s.done);
    workouts
      ..clear()
      ..addAll(s.workouts);
    if (stepSource == StepSource.sample) steps = s.steps;
    sample = true;
  }

  // Storage ------------------------------------------------------------

  void _changed() {
    _save();
    notifyListeners();
  }

  Map<String, Object?> toJson() => {
    'v': 1,
    'habits': habits.map((h) => h.toJson()).toList(),
    'done': {for (final e in done.entries) e.key: (e.value.toList()..sort())},
    'workouts': workouts.map((w) => w.toJson()).toList(),
    'steps': {for (final e in steps.entries) '${e.key}': e.value},
    'stepSource': stepSource.name,
    'sample': sample,
    'weeklyGoal': weeklyGoal,
    'stepGoal': stepGoal,
  };

  void _save() {
    try {
      prefs?.setString(storageKey, jsonEncode(toJson()));
    } catch (_) {
      // Storage full or gone: keep running from memory.
    }
  }

  /// Loads saved state. Returns false (and leaves things empty) when there is
  /// nothing saved or what is saved is unreadable.
  bool _load() {
    final raw = prefs?.getString(storageKey);
    if (raw == null) return false;
    try {
      final j = (jsonDecode(raw) as Map).cast<String, Object?>();
      if (j['v'] != 1) return false;
      final hs = [for (final h in j['habits'] as List) Habit.fromJson((h as Map).cast<String, Object?>())];
      final dn = <String, Set<int>>{
        for (final e in (j['done'] as Map).entries)
          e.key as String: (e.value as List).cast<num>().map((n) => n.toInt()).toSet(),
      };
      final ws = [for (final w in j['workouts'] as List) Workout.fromJson((w as Map).cast<String, Object?>())];
      final st = <int, int>{
        for (final e in (j['steps'] as Map? ?? const {}).entries) int.parse(e.key as String): (e.value as num).toInt(),
      };
      habits.addAll(hs);
      done.addAll(dn);
      workouts.addAll(ws);
      steps = st;
      stepSource = StepSource.values.asNameMap()[j['stepSource']] ?? StepSource.sample;
      sample = j['sample'] == true;
      weeklyGoal = (j['weeklyGoal'] as num?)?.toInt() ?? 3;
      stepGoal = (j['stepGoal'] as num?)?.toInt() ?? 8000;
      return true;
    } catch (_) {
      habits.clear();
      done.clear();
      workouts.clear();
      steps = {};
      return false;
    }
  }
}

/// Puts a [Tracker] in the tree; widgets rebuild when it changes.
class TrackerScope extends InheritedNotifier<Tracker> {
  const TrackerScope({super.key, required Tracker tracker, required super.child}) : super(notifier: tracker);

  static Tracker of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<TrackerScope>()!.notifier!;

  static Tracker read(BuildContext context) => context.getInheritedWidgetOfExactType<TrackerScope>()!.notifier!;
}
