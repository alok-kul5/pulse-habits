import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../brand/icons.dart';
import '../brand/tokens.dart';
import '../data/models.dart';
import '../state/tracker.dart';
import '../widgets/ui.dart';

/// Log a session. Strength starts from your last session's lifts, so a
/// repeat workout is two taps.
class WorkoutSheet extends StatefulWidget {
  const WorkoutSheet({super.key});

  @override
  State<WorkoutSheet> createState() => _WorkoutSheetState();
}

class _LiftDraft {
  _LiftDraft(this.exercise, this.sets, this.reps, this.kg);

  String exercise;
  int sets, reps;
  double kg;
}

class _WorkoutSheetState extends State<WorkoutSheet> {
  WorkoutKind _kind = WorkoutKind.strength;
  int _minutes = 45;
  double _km = 5;
  List<_LiftDraft> _lifts = [];
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final t = TrackerScope.read(context);
    final last = t.recentWorkouts.where((w) => w.kind == WorkoutKind.strength && w.lifts.isNotEmpty).firstOrNull;
    _lifts = last == null
        ? [_LiftDraft('Back squat', 5, 5, 60), _LiftDraft('Bench press', 4, 8, 40)]
        : [for (final l in last.lifts) _LiftDraft(l.exercise, l.sets, l.reps, l.kg)];
  }

  double get _volume => _lifts.fold(0.0, (a, l) => a + l.sets * l.reps * l.kg);

  void _save() {
    final t = TrackerScope.read(context);
    final w = t.logWorkout(
      kind: _kind,
      minutes: _minutes,
      lifts: _kind == WorkoutKind.strength
          ? [
              for (final l in _lifts)
                if (l.exercise.trim().isNotEmpty)
                  Lift(exercise: l.exercise.trim(), sets: l.sets, reps: l.reps, kg: l.kg),
            ]
          : const [],
      km: _kind == WorkoutKind.run || _kind == WorkoutKind.ride ? _km : 0,
    );
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop(w);
  }

  @override
  Widget build(BuildContext context) {
    final distance = _kind == WorkoutKind.run || _kind == WorkoutKind.ride;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log workout', style: Txt.display(30)),
          const SizedBox(height: 18),
          SizedBox(
            height: 84,
            child: Row(
              children: [
                for (final k in WorkoutKind.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Pressable(
                        semantics: k.label,
                        onTap: () => setState(() => _kind = k),
                        child: AnimatedContainer(
                          duration: Motion.of(context, Motion.base),
                          curve: Motion.out,
                          decoration: BoxDecoration(
                            gradient: k == _kind ? Palette.brand : null,
                            color: k == _kind ? null : Palette.raised,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: k == _kind ? Palette.glow(Palette.flare, .35, 16) : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: k == _kind ? 1.15 : 1,
                                duration: Motion.of(context, Motion.base),
                                curve: Motion.spring,
                                child: Icon(workoutIcon(k), color: k == _kind ? Colors.white : Palette.ink2),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                k.label,
                                style: Txt.text(
                                  11.5,
                                  weight: FontWeight.w800,
                                  color: k == _kind ? Colors.white : Palette.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Big(
                  label: 'Minutes',
                  value: '$_minutes',
                  onMinus: () => setState(() => _minutes = (_minutes - 5).clamp(5, 300)),
                  onPlus: () => setState(() => _minutes = (_minutes + 5).clamp(5, 300)),
                ),
              ),
              if (distance) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _Big(
                    label: 'Kilometres',
                    value: _km.toStringAsFixed(1),
                    onMinus: () => setState(() => _km = (_km - .5).clamp(.5, 300)),
                    onPlus: () => setState(() => _km = (_km + .5).clamp(.5, 300)),
                  ),
                ),
              ],
            ],
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.slow),
            curve: Motion.out,
            alignment: Alignment.topCenter,
            child: _kind != WorkoutKind.strength
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Eyebrow(
                        'Lifts',
                        trailing: Text('${compact(_volume)} KG TOTAL', style: Txt.label(10.5, color: Palette.ember)),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < _lifts.length; i++) _liftRow(i),
                      GhostButton(
                        label: 'Add exercise',
                        icon: Icons.add_rounded,
                        onTap: () => setState(() => _lifts.add(_LiftDraft('', 3, 10, 20))),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          GlowButton(label: 'Save workout', icon: Icons.check_rounded, onTap: _save),
        ],
      ),
    );
  }

  Widget _liftRow(int i) {
    final l = _lifts[i];
    return Container(
      key: ObjectKey(l),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 10),
      decoration: BoxDecoration(color: Palette.raised, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: l.exercise,
                  onChanged: (v) => l.exercise = v,
                  style: Txt.text(15, weight: FontWeight.w800),
                  cursorColor: Palette.ember,
                  decoration: InputDecoration(
                    hintText: 'Exercise',
                    hintStyle: Txt.text(15, color: Palette.ink3),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: () => setState(() => _lifts.removeAt(i)),
                icon: const Icon(Icons.close_rounded, color: Palette.ink3, size: 20),
              ),
            ],
          ),
          Row(
            children: [
              _Mini(
                label: 'sets',
                value: '${l.sets}',
                onTap: (d) => setState(() => l.sets = (l.sets + d).clamp(1, 20)),
              ),
              _Mini(
                label: 'reps',
                value: '${l.reps}',
                onTap: (d) => setState(() => l.reps = (l.reps + d).clamp(1, 100)),
              ),
              _Mini(
                label: 'kg',
                value: l.kg.toStringAsFixed(l.kg % 1 == 0 ? 0 : 1),
                onTap: (d) => setState(() => l.kg = (l.kg + d * 2.5).clamp(0, 500)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({required this.label, required this.value, required this.onMinus, required this.onPlus});

  final String label, value;
  final VoidCallback onMinus, onPlus;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
    decoration: BoxDecoration(color: Palette.raised, borderRadius: BorderRadius.circular(20)),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: Txt.label(10)),
              Text(value, style: Txt.display(30)),
            ],
          ),
        ),
        _Round(icon: Icons.remove_rounded, onTap: onMinus, semantics: 'Less $label'),
        const SizedBox(width: 6),
        _Round(icon: Icons.add_rounded, onTap: onPlus, semantics: 'More $label'),
      ],
    ),
  );
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.onTap});

  final String label, value;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      children: [
        _Round(icon: Icons.remove_rounded, onTap: () => onTap(-1), size: 28, semantics: 'Fewer $label'),
        Expanded(
          child: Column(
            children: [
              Text(value, style: Txt.text(15, weight: FontWeight.w800)),
              Text(
                label,
                style: Txt.text(10, weight: FontWeight.w600, color: Palette.ink3),
              ),
            ],
          ),
        ),
        _Round(icon: Icons.add_rounded, onTap: () => onTap(1), size: 28, semantics: 'More $label'),
      ],
    ),
  );
}

class _Round extends StatelessWidget {
  const _Round({required this.icon, required this.onTap, this.size = 38, required this.semantics});

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final String semantics;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: .85,
    semantics: semantics,
    child: Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Palette.card, shape: BoxShape.circle),
      child: Icon(icon, size: size * .55, color: Palette.ink),
    ),
  );
}
