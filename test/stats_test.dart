import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/data/days.dart';
import 'package:pulse/data/models.dart';
import 'package:pulse/data/seed.dart';
import 'package:pulse/data/stats.dart';
import 'package:pulse/data/streaks.dart';

final today = Days.of(DateTime(2026, 11, 25)); // a Wednesday

Habit habit(String id, {Set<int>? on, int age = 60}) =>
    Habit(id: id, name: id, icon: 'water', hue: 0, createdDay: today - age, weekdays: on);

void main() {
  final a = habit('a');
  final b = habit('b', on: {1, 3, 5});
  final done = {
    'a': {today, today - 1, today - 2},
    'b': {today - 2},
  };

  test('day score is the share of due habits done', () {
    expect(Stats.dayScore([a, b], done, today), .5); // b due Wed, not done
    expect(Stats.dayScore([a, b], done, today - 1), 1); // b not due Tue
    expect(Stats.dayScore([a, b], done, today - 2), 1);
    expect(Stats.dayScore([a, b], done, today - 3), 0);
    expect(Stats.dayScore([a], done, today - 100), isNull); // before it existed
  });

  test('heatmap levels', () {
    expect(Stats.level(null), -1);
    expect(Stats.level(0), 0);
    expect(Stats.level(.2), 1);
    expect(Stats.level(.5), 2);
    expect(Stats.level(.8), 3);
    expect(Stats.level(1), 4);
  });

  test('heatmap is whole weeks, Monday first, future days blank', () {
    final grid = Stats.heatmap(3, today, (d) => Stats.dayScore([a, b], done, d));
    expect(grid, hasLength(3));
    expect(grid.every((w) => w.length == 7), isTrue);
    final week = grid.last; // Mon 23 … Sun 29
    expect(week[0], 4); // Mon: a and b done
    expect(week[1], 4); // Tue: a done, b not due
    expect(week[2], 2); // Wed: half
    expect(week.sublist(3), everyElement(-2));
  });

  test('completion rate counts only scheduled days', () {
    // Mon–Wed: a due 3 (3 done), b due Mon+Wed (1 done) => 4/5.
    expect(Stats.completionRate([a, b], done, today - 2, today), closeTo(.8, 1e-9));
    expect(Stats.completionRate([a], done, today - 200, today - 100), isNull);
  });

  test('weekly completion stops at today in the current week', () {
    final rates = Stats.weeklyCompletion([a, b], done, 2, today);
    expect(rates, hasLength(2));
    expect(rates.last, closeTo(.8, 1e-9));
    expect(rates.first, 0);
  });

  test('completion by weekday', () {
    final r = Stats.byWeekday(b, done['b']!, 7, today);
    expect(r[0], 1); // Monday done
    expect(r[1], isNull); // not scheduled
    expect(r[2], 0); // Wednesday not done
  });

  test('weekly volume and minutes bucket by Monday week', () {
    final ws = [
      Workout(
        id: '1',
        day: today,
        kind: WorkoutKind.strength,
        minutes: 60,
        lifts: const [Lift(exercise: 'Squat', sets: 5, reps: 5, kg: 100)],
      ),
      Workout(id: '2', day: today - 3, kind: WorkoutKind.run, minutes: 30, km: 5), // last Sunday
      Workout(
        id: '3',
        day: today - 12,
        kind: WorkoutKind.strength,
        minutes: 45,
        lifts: const [Lift(exercise: 'Bench', sets: 3, reps: 10, kg: 60)],
      ),
      Workout(id: 'old', day: today - 400, kind: WorkoutKind.run, minutes: 99),
    ];
    expect(ws.first.volume, 2500);
    expect(Stats.weeklyVolume(ws, 3, today), [1800, 0, 2500]);
    expect(Stats.weeklyMinutes(ws, 3, today), [45, 30, 60]);
    expect(Stats.weeklySessions(ws, 3, today), [1, 1, 1]);
  });

  test('step series, moving average and trend', () {
    final steps = {today: 9000, today - 1: 3000};
    expect(Stats.stepSeries(steps, 3, today), [0, 3000, 9000]);
    expect(Stats.movingAverage([2, 4, 6, 8], 2), [2, 3, 5, 7]);
    expect(Stats.trend([100, 100, 150, 150]), closeTo(.5, 1e-9));
    expect(Stats.trend([0, 0, 1, 1]), isNull);
  });

  test('sample data is stable and opens on a live streak', () {
    final s1 = SampleData.build(today);
    final s2 = SampleData.build(today);
    expect(s1.workouts.length, s2.workouts.length);
    expect(s1.steps[today - 10], s2.steps[today - 10]);
    expect(Streak.perfectDays(s1.habits, s1.done, today).current, greaterThanOrEqualTo(6));
    // Today is part done, so there is something to tick in the demo.
    final score = Stats.dayScore(s1.habits, s1.done, today)!;
    expect(score, greaterThan(0));
    expect(score, lessThan(1));
    // Progressive overload: later weeks lift more.
    final vol = Stats.weeklyVolume(s1.workouts, 26, today);
    expect(vol.skip(20).reduce((x, y) => x + y), greaterThan(vol.take(6).reduce((x, y) => x + y)));
  });
}
