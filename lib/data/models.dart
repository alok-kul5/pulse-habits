import 'days.dart';

/// A habit: something to do on some days of the week.
class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.hue,
    required this.createdDay,
    Set<int>? weekdays,
    this.reminder,
  }) : weekdays = weekdays ?? {1, 2, 3, 4, 5, 6, 7};

  final String id;
  String name;

  /// Key into the icon set (see `brand/icons.dart`).
  String icon;

  /// Index into the habit palette.
  int hue;

  /// The first day it counts from. Days before it never break a streak.
  final int createdDay;

  /// Scheduled weekdays, 1 = Monday … 7 = Sunday. Never empty.
  Set<int> weekdays;

  /// Daily reminder as minutes after midnight, or null for none.
  int? reminder;

  bool scheduledOn(int day) => day >= createdDay && weekdays.contains(Days.weekday(day));

  bool get everyDay => weekdays.length == 7;

  /// "Every day", "Weekdays", "Mon, Wed, Fri".
  String get scheduleLabel {
    if (everyDay) return 'Every day';
    final s = weekdays.toList()..sort();
    if (s.length == 5 && s.every((d) => d <= 5)) return 'Weekdays';
    if (s.length == 2 && s.contains(6) && s.contains(7)) return 'Weekends';
    if (s.length >= 4) return '${s.length}× a week';
    return s.map((d) => Days.weekdayShort[d - 1]).join(', ');
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'hue': hue,
    'created': createdDay,
    'days': (weekdays.toList()..sort()),
    'reminder': reminder,
  };

  static Habit fromJson(Map<String, Object?> j) {
    final days = (j['days'] as List).cast<num>().map((n) => n.toInt()).where((d) => d >= 1 && d <= 7).toSet();
    return Habit(
      id: j['id'] as String,
      name: j['name'] as String,
      icon: j['icon'] as String,
      hue: (j['hue'] as num).toInt(),
      createdDay: (j['created'] as num).toInt(),
      weekdays: days.isEmpty ? null : days,
      reminder: (j['reminder'] as num?)?.toInt(),
    );
  }
}

enum WorkoutKind {
  strength('Strength', 'strength'),
  run('Run', 'run'),
  ride('Ride', 'ride'),
  hiit('HIIT', 'hiit'),
  yoga('Yoga', 'yoga');

  const WorkoutKind(this.label, this.key);
  final String label;
  final String key;

  static WorkoutKind byKey(String k) => values.firstWhere((v) => v.key == k, orElse: () => strength);
}

/// One exercise in a strength session: sets × reps at a weight.
class Lift {
  const Lift({required this.exercise, required this.sets, required this.reps, required this.kg});

  final String exercise;
  final int sets;
  final int reps;
  final double kg;

  /// Tonnage: every rep times the weight moved.
  double get volume => sets * reps * kg;

  Map<String, Object?> toJson() => {'e': exercise, 's': sets, 'r': reps, 'kg': kg};

  static Lift fromJson(Map<String, Object?> j) => Lift(
    exercise: j['e'] as String,
    sets: (j['s'] as num).toInt(),
    reps: (j['r'] as num).toInt(),
    kg: (j['kg'] as num).toDouble(),
  );
}

class Workout {
  const Workout({
    required this.id,
    required this.day,
    required this.kind,
    required this.minutes,
    this.lifts = const [],
    this.km = 0,
  });

  final String id;
  final int day;
  final WorkoutKind kind;
  final int minutes;
  final List<Lift> lifts;
  final double km;

  double get volume => lifts.fold(0.0, (a, l) => a + l.volume);

  String get title => switch (kind) {
    WorkoutKind.strength => lifts.isEmpty ? 'Strength' : lifts.map((l) => l.exercise).take(2).join(' + '),
    WorkoutKind.run || WorkoutKind.ride => '${km.toStringAsFixed(km < 10 ? 1 : 0)} km ${kind.label.toLowerCase()}',
    _ => kind.label,
  };

  Map<String, Object?> toJson() => {
    'id': id,
    'day': day,
    'kind': kind.key,
    'min': minutes,
    if (lifts.isNotEmpty) 'lifts': lifts.map((l) => l.toJson()).toList(),
    if (km > 0) 'km': km,
  };

  static Workout fromJson(Map<String, Object?> j) => Workout(
    id: j['id'] as String,
    day: (j['day'] as num).toInt(),
    kind: WorkoutKind.byKey(j['kind'] as String),
    minutes: (j['min'] as num).toInt(),
    lifts: [for (final l in (j['lifts'] as List? ?? const [])) Lift.fromJson((l as Map).cast<String, Object?>())],
    km: (j['km'] as num?)?.toDouble() ?? 0,
  );
}
