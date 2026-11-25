import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/data/days.dart';
import 'package:pulse/data/models.dart';
import 'package:pulse/data/streaks.dart';

// Wed 25 Nov 2026.
final today = Days.of(DateTime(2026, 11, 25));

Habit habit({Set<int>? on, int age = 60, String id = 'h'}) =>
    Habit(id: id, name: id, icon: 'water', hue: 0, createdDay: today - age, weekdays: on);

Set<int> back(List<int> ago) => {for (final a in ago) today - a};

void main() {
  test('days are plain integers that ignore time of day', () {
    expect(Days.of(DateTime(2026, 11, 25, 23, 59)), Days.of(DateTime(2026, 11, 25)));
    expect(Days.weekday(today), DateTime.wednesday);
    expect(Days.weekday(Days.weekStart(today)), DateTime.monday);
    expect(Days.weekStart(today), today - 2);
    expect(Days.label(today), 'Wed 25 Nov');
    expect(Days.relative(today - 1, today), 'Yesterday');
  });

  group('one habit', () {
    test('counts done days in a row up to today', () {
      final s = Streak.ofHabit(habit(), back([0, 1, 2, 3, 5]), today);
      expect(s.current, 4);
      expect(s.best, 4);
    });

    test('an unticked today does not break yesterday\'s streak', () {
      final s = Streak.ofHabit(habit(), back([1, 2, 3]), today);
      expect(s.current, 3);
    });

    test('an unticked yesterday does', () {
      final s = Streak.ofHabit(habit(), back([2, 3, 4]), today);
      expect(s.current, 0);
      expect(s.best, 3);
    });

    test('unscheduled days are skipped, not missed', () {
      // Mon, Wed, Fri only. Today is Wednesday.
      final h = habit(on: {1, 3, 5});
      // Mon (2 ago), Fri (5 ago), Wed (7 ago), Mon (9 ago).
      final s = Streak.ofHabit(h, back([0, 2, 5, 7, 9]), today);
      expect(s.current, 5);
    });

    test('a missed scheduled day breaks it', () {
      final h = habit(on: {1, 3, 5});
      final s = Streak.ofHabit(h, back([0, 2, 7, 9]), today); // Fri (5 ago) missed
      expect(s.current, 2);
      expect(s.best, 2);
    });

    test('doing it on a day off counts as a bonus', () {
      final h = habit(on: {1, 3, 5});
      final s = Streak.ofHabit(h, back([0, 1, 2]), today); // Tue is a bonus
      expect(s.current, 3);
    });

    test('days before the habit existed never count against it', () {
      final h = habit(age: 2);
      final s = Streak.ofHabit(h, back([0, 1, 2]), today);
      expect(s.current, 3);
      expect(s.best, 3);
      expect(Streak.ofHabit(h, back([5, 6]), today), isA<Streak>().having((s) => s.current, 'current', 0));
    });

    test('best keeps the longest run, even an old one', () {
      final s = Streak.ofHabit(habit(), back([0, 1, 10, 11, 12, 13, 14, 15]), today);
      expect(s.current, 2);
      expect(s.best, 6);
    });

    test('nothing done is zero', () {
      expect(Streak.ofHabit(habit(), {}, today).best, 0);
    });
  });

  group('perfect days', () {
    test('needs every scheduled habit', () {
      final a = habit(id: 'a');
      final b = habit(id: 'b');
      final s = Streak.perfectDays(
        [a, b],
        {
          'a': back([0, 1, 2, 3]),
          'b': back([1, 2]),
        },
        today,
      );
      expect(s.current, 2); // today is still open for b
      expect(s.best, 2);
    });

    test('a habit off that day does not block it', () {
      final a = habit(id: 'a');
      final b = habit(id: 'b', on: {1, 3, 5}); // not Tuesday
      final s = Streak.perfectDays(
        [a, b],
        {
          'a': back([1, 2]),
          'b': back([2]),
        },
        today,
      );
      expect(s.current, 2);
    });

    test('no habits is no streak', () {
      expect(Streak.perfectDays([], {}, today).current, 0);
    });
  });

  group('workout weeks', () {
    Workout w(int ago) => Workout(id: '$ago', day: today - ago, kind: WorkoutKind.run, minutes: 30);

    test('a week counts once it reaches the goal', () {
      // This week (Mon–Wed): 1 session, still open. The two before: 4 and 3.
      final ws = [w(0), w(3), w(4), w(6), w(9), w(11), w(13), w(15)];
      final s = Streak.workoutWeeks(ws, 3, today);
      expect(s.current, 2);
    });

    test('an empty past week breaks it', () {
      final ws = [w(3), w(4), w(5), w(17), w(18), w(19)];
      expect(Streak.workoutWeeks(ws, 3, today).current, 1);
      expect(Streak.workoutWeeks(ws, 3, today).best, 1);
    });

    test('this week counts as soon as the goal is met', () {
      final ws = [w(0), w(1), w(2)];
      expect(Streak.workoutWeeks(ws, 3, today).current, 1);
    });
  });
}
