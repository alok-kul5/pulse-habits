import 'dart:math' as math;

import 'days.dart';
import 'models.dart';

/// Six months of believable history for the demo: habits that get steadier
/// over time, three strength sessions a week with slow progressive overload,
/// a weekend run, and steps that climb on weekends. Seeded, so every launch
/// (and every screenshot) looks the same for the same day.
class SampleData {
  SampleData._(this.habits, this.done, this.workouts, this.steps);

  final List<Habit> habits;
  final Map<String, Set<int>> done;
  final List<Workout> workouts;
  final Map<int, int> steps;

  static const days = 182;

  factory SampleData.build(int today) {
    final r = math.Random(7);
    final start = today - days;

    Habit h(String id, String name, String icon, int hue, {Set<int>? on, int? reminder, int age = days}) =>
        Habit(id: id, name: name, icon: icon, hue: hue, createdDay: today - age, weekdays: on, reminder: reminder);

    final habits = [
      h('water', 'Drink 2 L of water', 'water', 3, reminder: 10 * 60),
      h('read', 'Read 20 pages', 'book', 1, reminder: 21 * 60 + 30),
      h('meditate', 'Meditate 10 minutes', 'mind', 5, reminder: 7 * 60),
      h('stretch', 'Morning stretch', 'stretch', 2, on: {1, 2, 3, 4, 5}),
      h('screens', 'No screens after 11', 'moon', 6, age: 64),
      h('journal', 'Journal', 'pen', 4, on: {1, 3, 5, 7}, age: 120),
    ];
    // How likely each habit is on a given day, at the start and by now.
    const odds = {
      'water': (.72, .95),
      'read': (.5, .85),
      'meditate': (.35, .8),
      'stretch': (.55, .9),
      'screens': (.4, .7),
      'journal': (.45, .8),
    };

    final done = <String, Set<int>>{for (final x in habits) x.id: <int>{}};
    for (var d = start; d < today; d++) {
      final progress = (d - start) / days;
      // A rough patch about two months in, like real life.
      final slump = (d - start > 55 && d - start < 66) ? .45 : 0.0;
      for (final x in habits) {
        if (!x.scheduledOn(d)) continue;
        final (a, b) = odds[x.id]!;
        // The last stretch is clean, so the demo opens on a live streak.
        if (today - d <= 6 || r.nextDouble() < a + (b - a) * progress - slump) done[x.id]!.add(d);
      }
    }
    // Today: two of the morning ones are already ticked.
    done['water']!.add(today);
    if (habits[3].scheduledOn(today)) done['stretch']!.add(today);
    if (!habits[3].scheduledOn(today)) done['meditate']!.add(today);

    // Workouts.
    final workouts = <Workout>[];
    var n = 0;
    for (var d = start; d <= today; d++) {
      final wd = Days.weekday(d);
      final week = (d - start) / 7;
      final slump = (d - start > 55 && d - start < 66);
      if ((wd == 1 || wd == 3 || wd == 5) && d < today && !slump && r.nextDouble() < .88) {
        final bump = (week / 2).floor() * 1.25; // +1.25 kg every fortnight
        final kind = wd == 1 ? 0 : (wd == 3 ? 1 : 2);
        final lifts = switch (kind) {
          0 => [
            Lift(exercise: 'Bench press', sets: 4, reps: 8, kg: 50 + bump),
            Lift(exercise: 'Overhead press', sets: 3, reps: 8, kg: 30 + bump * .5),
            Lift(exercise: 'Dips', sets: 3, reps: 10, kg: 0 + bump * .4),
          ],
          1 => [
            Lift(exercise: 'Back squat', sets: 5, reps: 5, kg: 70 + bump * 1.6),
            Lift(exercise: 'Romanian deadlift', sets: 3, reps: 10, kg: 60 + bump),
            Lift(exercise: 'Lunges', sets: 3, reps: 12, kg: 16 + bump * .3),
          ],
          _ => [
            Lift(exercise: 'Deadlift', sets: 3, reps: 5, kg: 90 + bump * 2),
            Lift(exercise: 'Barbell row', sets: 4, reps: 8, kg: 45 + bump),
            Lift(exercise: 'Pull-ups', sets: 3, reps: 8, kg: 0 + bump * .4),
          ],
        };
        workouts.add(
          Workout(id: 'w${n++}', day: d, kind: WorkoutKind.strength, minutes: 50 + r.nextInt(20), lifts: lifts),
        );
      }
      if (wd == 6 && d < today && r.nextDouble() < .8) {
        final km = 4.0 + week * .12 + r.nextDouble() * 1.5;
        workouts.add(Workout(id: 'w${n++}', day: d, kind: WorkoutKind.run, minutes: (km * 6.1).round(), km: km));
      }
      if (wd == 7 && d < today && r.nextDouble() < .45) {
        workouts.add(Workout(id: 'w${n++}', day: d, kind: WorkoutKind.yoga, minutes: 30 + r.nextInt(3) * 5));
      }
      if (wd == 2 && d < today && r.nextDouble() < .3) {
        workouts.add(Workout(id: 'w${n++}', day: d, kind: WorkoutKind.ride, minutes: 40, km: 14 + r.nextDouble() * 6));
      }
    }

    // Steps.
    final steps = <int, int>{};
    for (var d = start; d <= today; d++) {
      final wd = Days.weekday(d);
      final progress = (d - start) / days;
      var s = 5600 + 2400 * progress + (wd >= 6 ? 2600 : 0) + (r.nextDouble() - .5) * 3400;
      if (workouts.any((w) => w.day == d && w.kind == WorkoutKind.run)) s += 5200;
      if (d == today) s *= .58; // the day isn't over
      steps[d] = s.round().clamp(900, 24000);
    }

    return SampleData._(habits, done, workouts, steps);
  }
}
