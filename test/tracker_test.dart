import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/data/days.dart';
import 'package:pulse/data/models.dart';
import 'package:pulse/state/tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

final today = Days.of(DateTime(2026, 11, 25));

Future<SharedPreferences> prefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  test('first launch opens on the sample history', () async {
    final t = Tracker(prefs: await prefs(), clock: () => today);
    expect(t.sample, isTrue);
    expect(t.habits, hasLength(6));
    expect(t.workouts, isNotEmpty);
    expect(t.doneToday, greaterThan(0));
    expect(t.doneToday, lessThan(t.dueToday.length));
  });

  test('ticking toggles and saves', () async {
    final p = await prefs();
    final t = Tracker(prefs: p, clock: () => today);
    final h = t.dueToday.firstWhere((h) => !t.isDone(h.id, today));
    final before = t.doneToday;
    expect(t.toggle(h.id), isTrue);
    expect(t.doneToday, before + 1);
    expect(t.toggle(h.id), isFalse);
    expect(t.doneToday, before);

    t.toggle(h.id);
    final again = Tracker(prefs: p, clock: () => today);
    expect(again.isDone(h.id, today), isTrue);
    expect(again.habits.map((h) => h.name), t.habits.map((h) => h.name));
    expect(again.workouts.length, t.workouts.length);
    expect(again.steps[today], t.steps[today]);
  });

  test('a past day can be filled in late', () async {
    final t = Tracker(prefs: await prefs(), clock: () => today, seed: false);
    final h = t.addHabit(name: '  Walk  ', icon: 'walk', hue: 2);
    expect(h.name, 'Walk');
    expect(h.createdDay, today);
    t.toggle(h.id, today - 1);
    expect(t.isDone(h.id, today - 1), isTrue);
  });

  test('start fresh empties everything, load sample brings it back', () async {
    final t = Tracker(prefs: await prefs(), clock: () => today);
    t.startFresh();
    expect(t.habits, isEmpty);
    expect(t.workouts, isEmpty);
    expect(t.sample, isFalse);
    expect(t.perfectStreak.current, 0);
    t.loadSample();
    expect(t.habits, hasLength(6));
    expect(t.sample, isTrue);
  });

  test('delete with undo puts the habit and its history back in place', () async {
    final t = Tracker(prefs: await prefs(), clock: () => today);
    final h = t.habits[2];
    final ticks = t.done[h.id]!.length;
    final removed = t.removeHabit(h.id)!;
    expect(t.habit(h.id), isNull);
    t.restoreHabit(removed);
    expect(t.habits[2].id, h.id);
    expect(t.done[h.id]!.length, ticks);
  });

  test('logging a workout counts toward the week', () async {
    final t = Tracker(prefs: await prefs(), clock: () => today, seed: false);
    t.setWeeklyGoal(2);
    t.logWorkout(kind: WorkoutKind.run, minutes: 30, km: 5);
    expect(t.sessionsThisWeek, 1);
    expect(t.workoutStreak.current, 0);
    t.logWorkout(
      kind: WorkoutKind.strength,
      minutes: 50,
      lifts: const [Lift(exercise: 'Squat', sets: 5, reps: 5, kg: 80)],
    );
    expect(t.sessionsThisWeek, 2);
    expect(t.workoutStreak.current, 1);
    expect(t.recentWorkouts.first.volume, 2000);
  });

  test('goals are kept in range', () async {
    final t = Tracker(prefs: await prefs(), clock: () => today, seed: false);
    t.setWeeklyGoal(12);
    t.setStepGoal(200);
    expect(t.weeklyGoal, 7);
    expect(t.stepGoal, 1000);
  });

  test('corrupt or unknown storage is dropped, not a crash', () async {
    final bad = Tracker(prefs: await prefs({Tracker.storageKey: '{not json'}), clock: () => today);
    expect(bad.habits, hasLength(6)); // falls back to the sample
    final future = Tracker(
      prefs: await prefs({
        Tracker.storageKey: jsonEncode({'v': 99}),
      }),
      clock: () => today,
      seed: false,
    );
    expect(future.habits, isEmpty);
  });

  test('real steps replace the sample ones', () async {
    final t = Tracker(prefs: await prefs(), clock: () => today);
    t.setHealthSteps({today: 4321});
    expect(t.stepSource, StepSource.health);
    expect(t.stepsToday, 4321);
    t.startFresh();
    expect(t.stepsToday, 4321, reason: 'starting fresh keeps real steps');
  });
}
