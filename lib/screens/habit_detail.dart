import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';
import '../data/days.dart';
import '../data/stats.dart';
import '../state/tracker.dart';
import '../widgets/charts.dart';
import '../widgets/check.dart';
import '../widgets/habit_card.dart';
import '../widgets/heatmap.dart';
import '../widgets/ui.dart';
import 'habit_sheet.dart';
import 'routes.dart';

/// One habit up close. Its tile flies in from the list; the page takes on
/// the habit's colour.
class HabitDetail extends StatelessWidget {
  const HabitDetail({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    final t = TrackerScope.of(context);
    final h = t.habit(habitId);
    if (h == null) return const Scaffold(backgroundColor: Palette.night);
    final c = Palette.hue(h.hue);
    final done = t.done[h.id] ?? const <int>{};
    final streak = t.streakOf(h);
    final rate30 = Stats.completionRate([h], t.done, t.today - 29, t.today);
    final weekly = Stats.weeklyCompletion([h], t.done, 12, t.today).map((v) => (v ?? 0) * 100).toList();
    final byDay = Stats.byWeekday(h, done, 84, t.today).map((v) => (v ?? 0) * 100).toList();
    final top = MediaQuery.paddingOf(context).top;
    final isDone = t.isDone(h.id, t.today);
    var k = 0;
    Duration next() => Duration(milliseconds: 70 * k++);

    return Scaffold(
      backgroundColor: Palette.night,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 380,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.withValues(alpha: .32), c.withValues(alpha: .08), Palette.night],
                  ),
                ),
              ),
            ),
          ),
          ListView(
            padding: EdgeInsets.fromLTRB(20, top + 6, 20, 40),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Palette.ink),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => showPulseSheet(context, (_) => HabitSheet(habit: h)),
                    icon: const Icon(Icons.edit_rounded, color: Palette.ink),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () {
                      final removed = t.removeHabit(h.id);
                      Navigator.of(context).pop();
                      if (removed != null) {
                        toast(context, 'Deleted ${h.name}', action: 'Undo', onAction: () => t.restoreHabit(removed));
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Palette.ink),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  HabitTile(habit: h, size: 84),
                  const Spacer(),
                  if (h.scheduledOn(t.today) || isDone)
                    Column(
                      children: [
                        CheckOrb(
                          done: isDone,
                          color: c,
                          size: 58,
                          onTap: () => t.toggle(h.id),
                          label: isDone ? 'Done today. Tap to undo' : 'Tick off today',
                        ),
                        const SizedBox(height: 6),
                        Text(isDone ? 'DONE TODAY' : 'TODAY', style: Txt.label(10, color: isDone ? c : Palette.ink3)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Reveal(
                delay: next(),
                child: Text(h.name, style: Txt.display(36, height: 1.05)),
              ),
              const SizedBox(height: 6),
              Reveal(
                delay: next(),
                child: Text(
                  '${h.scheduleLabel}${h.reminder == null ? '' : '  ·  reminder ${clock(h.reminder!)}'}  ·  since ${Days.short(h.createdDay)}',
                  style: Txt.text(14, weight: FontWeight.w600, color: Palette.ink2),
                ),
              ),
              const SizedBox(height: 22),
              Reveal(
                delay: next(),
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(label: 'Streak', value: streak.current, unit: 'days', color: c, big: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stat(label: 'Best', value: streak.best, unit: 'days', color: c),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stat(label: '30 days', value: ((rate30 ?? 0) * 100).round(), unit: '%', color: c),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Reveal(
                delay: next(),
                child: PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('Last 26 weeks'),
                      const SizedBox(height: 14),
                      Heatmap(
                        weeks: 26,
                        today: t.today,
                        color: c,
                        score: (d) => h.scheduledOn(d) || done.contains(d) ? (done.contains(d) ? 1 : 0) : null,
                        describe: (d) =>
                            '${Days.label(d)} · ${done.contains(d) ? 'done' : (h.scheduledOn(d) ? 'missed' : 'day off')}',
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
                      const Eyebrow('Completion, week by week'),
                      const SizedBox(height: 10),
                      LineChart(
                        values: weekly,
                        color: c,
                        min: 0,
                        max: 105,
                        format: (v) => '${v.round()}%',
                        label: (i) => 'wk of ${Days.short(Days.weekStart(t.today) - (11 - i) * 7)}',
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
                      const Eyebrow('By weekday, last 12 weeks'),
                      const SizedBox(height: 10),
                      BarChart(values: byDay, labels: Days.weekdayShort, color: c, format: (v) => '${v.round()}%'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.unit, required this.color, this.big = false});

  final String label, unit;
  final int value;
  final Color color;
  final bool big;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
    decoration: BoxDecoration(
      color: big ? null : Palette.card,
      gradient: big ? LinearGradient(colors: [color.withValues(alpha: .35), color.withValues(alpha: .12)]) : null,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: big ? color.withValues(alpha: .5) : Palette.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: Txt.label(10, color: big ? Palette.ink : Palette.ink3)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CountUp(value, style: Txt.display(30)),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: Txt.text(12, weight: FontWeight.w700, color: Palette.ink2),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
