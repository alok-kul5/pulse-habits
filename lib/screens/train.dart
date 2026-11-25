import 'package:material_ui/material_ui.dart';

import '../brand/icons.dart';
import '../brand/tokens.dart';
import '../data/days.dart';
import '../data/models.dart';
import '../data/stats.dart';
import '../state/tracker.dart';
import '../widgets/charts.dart';
import '../widgets/confetti.dart';
import '../widgets/ring.dart';
import '../widgets/ui.dart';
import 'routes.dart';
import 'workout_sheet.dart';

class TrainScreen extends StatelessWidget {
  const TrainScreen({super.key});

  static Future<void> log(BuildContext context) async {
    final t = TrackerScope.read(context);
    final before = t.sessionsThisWeek;
    final w = await showPulseSheet<Workout>(context, (_) => const WorkoutSheet());
    if (w == null || !context.mounted) return;
    if (before < t.weeklyGoal && t.sessionsThisWeek >= t.weeklyGoal) {
      final s = t.workoutStreak.current;
      celebrate(
        context,
        origin: MediaQuery.sizeOf(context).center(Offset.zero),
        title: 'Week done',
        subtitle: s > 1 ? '$s weeks in a row' : 'Weekly goal hit',
      );
    } else {
      toast(context, 'Logged: ${w.title}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = TrackerScope.of(context);
    final today = t.today;
    final vol = Stats.weeklyVolume(t.workouts, 8, today);
    final firstWeek = Days.weekStart(today) - 7 * 7;
    final thisWeek = t.workouts.where((w) => w.day >= Days.weekStart(today) && w.day <= today).toList();
    final minutes = thisWeek.fold(0, (a, w) => a + w.minutes);
    final recent = t.recentWorkouts.take(12).toList();
    final bests = _bests(t.workouts);
    final top = MediaQuery.paddingOf(context).top;
    var k = 0;
    Duration next() => Duration(milliseconds: 70 * k++);

    return Stack(
      children: [
        Positioned(
          top: -150,
          left: -150,
          child: IgnorePointer(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Palette.sky.withValues(alpha: .16), Colors.transparent]),
              ),
            ),
          ),
        ),
        ListView(
          padding: EdgeInsets.fromLTRB(20, top + 18, 20, 130),
          children: [
            Reveal(
              delay: next(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text('Train', style: Txt.display(46))),
                  GlowButton(label: 'Log workout', icon: Icons.add_rounded, expand: false, onTap: () => log(context)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Reveal(
              delay: next(),
              scale: .94,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF14213A), Color(0xFF151325), Palette.card],
                  ),
                  border: Border.all(color: Palette.sky.withValues(alpha: .25)),
                ),
                child: Row(
                  children: [
                    ProgressRing(
                      value: t.sessionsThisWeek / t.weeklyGoal,
                      size: 132,
                      stroke: 14,
                      colors: const [Palette.sky, Color(0xFF9D7BFF), Palette.sky],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              RollingNumber(t.sessionsThisWeek, style: Txt.display(40)),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Text('/${t.weeklyGoal}', style: Txt.display(18, color: Palette.ink3)),
                              ),
                            ],
                          ),
                          Text('THIS WEEK', style: Txt.label(9.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt_rounded, color: Palette.sky, size: 30),
                              RollingNumber(t.workoutStreak.current, style: Txt.display(38)),
                            ],
                          ),
                          Text(
                            'week streak',
                            style: Txt.text(13, weight: FontWeight.w700, color: Palette.ink2),
                          ),
                          const SizedBox(height: 12),
                          Container(height: 1, color: Palette.line),
                          const SizedBox(height: 10),
                          _Row(label: 'Volume', value: '${compact(vol.last)} kg'),
                          const SizedBox(height: 5),
                          _Row(label: 'Time', value: '$minutes min'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Reveal(
              delay: next(),
              child: PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Strength volume, 8 weeks'),
                    const SizedBox(height: 10),
                    BarChart(
                      values: vol,
                      labels: [for (var i = 0; i < 8; i++) Days.short(firstWeek + i * 7).split(' ').first],
                      format: (v) => '${compact(v)} kg',
                    ),
                  ],
                ),
              ),
            ),
            if (bests.isNotEmpty) ...[
              const SizedBox(height: 22),
              Reveal(delay: next(), child: const Eyebrow('Personal bests')),
              const SizedBox(height: 10),
              Reveal(
                delay: next(),
                child: SizedBox(
                  height: 104,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: bests.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final (name, kg, day) = bests[i];
                      return Container(
                        width: 148,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Palette.card,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Palette.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Txt.text(13, weight: FontWeight.w700, color: Palette.ink2),
                            ),
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                CountUp(
                                  kg,
                                  style: Txt.display(30),
                                  format: (v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 3, bottom: 4),
                                  child: Text(
                                    'kg',
                                    style: Txt.text(12, weight: FontWeight.w800, color: Palette.ink3),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              Days.short(day),
                              style: Txt.text(11.5, weight: FontWeight.w600, color: Palette.ink3),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            Reveal(delay: next(), child: const Eyebrow('Recent')),
            const SizedBox(height: 10),
            if (recent.isEmpty)
              Reveal(
                delay: next(),
                child: PanelCard(
                  child: Text(
                    'No workouts yet. Log one and the charts come alive.',
                    style: Txt.text(14, color: Palette.ink2),
                  ),
                ),
              ),
            for (final w in recent)
              Padding(
                key: ValueKey(w.id),
                padding: const EdgeInsets.only(bottom: 10),
                child: Reveal(
                  delay: next(),
                  child: Dismissible(
                    key: ValueKey('d-${w.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: Palette.flare.withValues(alpha: .25),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.delete_rounded, color: Palette.flare),
                    ),
                    onDismissed: (_) {
                      t.removeWorkout(w.id);
                      toast(
                        context,
                        'Removed ${w.title}',
                        action: 'Undo',
                        onAction: () =>
                            t.logWorkout(kind: w.kind, minutes: w.minutes, lifts: w.lifts, km: w.km, day: w.day),
                      );
                    },
                    child: _WorkoutRow(w: w, today: today),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Heaviest weight per lifted exercise, most recent first on ties.
  static List<(String, double, int)> _bests(List<Workout> ws) {
    final best = <String, (double, int)>{};
    for (final w in ws) {
      for (final l in w.lifts) {
        if (l.kg <= 0) continue;
        final b = best[l.exercise];
        if (b == null || l.kg >= b.$1) best[l.exercise] = (l.kg, w.day);
      }
    }
    final out = [for (final e in best.entries) (e.key, e.value.$1, e.value.$2)];
    out.sort((a, b) => b.$2.compareTo(a.$2));
    return out;
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Txt.text(12.5, weight: FontWeight.w600, color: Palette.ink3),
        ),
      ),
      Text(value, style: Txt.text(13, weight: FontWeight.w800)),
    ],
  );
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({required this.w, required this.today});

  final Workout w;
  final int today;

  Color get _c => switch (w.kind) {
    WorkoutKind.strength => Palette.ember,
    WorkoutKind.run => Palette.volt,
    WorkoutKind.ride => Palette.sky,
    WorkoutKind.hiit => Palette.flare,
    WorkoutKind.yoga => const Color(0xFF9D7BFF),
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Palette.card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Palette.line.withValues(alpha: .8)),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: _c.withValues(alpha: .16), borderRadius: BorderRadius.circular(15)),
          child: Icon(workoutIcon(w.kind), color: _c, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                w.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Txt.text(15, weight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                '${Days.relative(w.day, today)}  ·  ${w.minutes} min${w.volume > 0 ? '  ·  ${compact(w.volume)} kg' : ''}',
                style: Txt.text(12.5, weight: FontWeight.w600, color: Palette.ink3),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
