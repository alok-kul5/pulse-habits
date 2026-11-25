import 'package:material_ui/material_ui.dart';

import '../data/models.dart';

/// The icons a habit can wear. Stored by key so saved data never depends on
/// font code points.
abstract final class HabitIcons {
  static const all = <String, IconData>{
    'water': Icons.water_drop_rounded,
    'book': Icons.menu_book_rounded,
    'mind': Icons.self_improvement_rounded,
    'stretch': Icons.accessibility_new_rounded,
    'moon': Icons.bedtime_rounded,
    'pen': Icons.edit_rounded,
    'run': Icons.directions_run_rounded,
    'bolt': Icons.bolt_rounded,
    'leaf': Icons.eco_rounded,
    'sun': Icons.wb_sunny_rounded,
    'heart': Icons.favorite_rounded,
    'pill': Icons.medication_rounded,
    'music': Icons.music_note_rounded,
    'code': Icons.code_rounded,
    'lang': Icons.translate_rounded,
    'walk': Icons.directions_walk_rounded,
    'food': Icons.restaurant_rounded,
    'money': Icons.savings_rounded,
  };

  static IconData of(String key) => all[key] ?? Icons.bolt_rounded;
}

IconData workoutIcon(WorkoutKind k) => switch (k) {
  WorkoutKind.strength => Icons.fitness_center_rounded,
  WorkoutKind.run => Icons.directions_run_rounded,
  WorkoutKind.ride => Icons.directions_bike_rounded,
  WorkoutKind.hiit => Icons.local_fire_department_rounded,
  WorkoutKind.yoga => Icons.self_improvement_rounded,
};
