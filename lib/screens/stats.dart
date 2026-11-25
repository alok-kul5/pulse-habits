import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';
import '../data/days.dart';
import '../data/stats.dart';
import '../state/tracker.dart';
import '../widgets/charts.dart';
import '../widgets/heatmap.dart';
import '../widgets/ui.dart';

enum Range {
  w4('4W', 4),
  w12('12W', 12),
  w26('26W', 26);

  const Range(this.label, this.weeks);
  final String label;
  final int weeks;
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Range _range = Range.w12;
  bool _minutes = false;

  @override
  Widget build(BuildContext context) {
    final t = TrackerScope.of(context);
    final today = t.today;
    final weeks = _range.weeks;
    final days = weeks * 7;
    final from = today - days + 1;
    final firstWeek = Days.weekStart(today) - (weeks - 1) * 7;

    // Completion: daily over 4 weeks, weekly beyond that.
    final completion = _range == Range.w4
        ? [for (var d = from; d <= today; d++) (t.dayScore(d) ?? 0) * 100]
        : Stats.weeklyCompletion(t.habits, t.done, weeks, today).map((v) => (v ?? 0) * 100).toList();
    final rate = Stats.completionRate(t.habits, t.done, from, today);
    final perfect = [for (var d = from; d <= today; d++) t.dayScore(d)].where((s) => s == 1).length;

    final load = _minutes
        ? Stats.weeklyMinutes(t.workouts, weeks, today)
        : Stats.weeklyVolume(t.workouts, weeks, today);
    final sessions = Stats.weeklySessions(t.workouts, weeks, today).fold(0, (a, b) => a + b);
    final weekLabels = [for (var i = 0; i < weeks; i++) Days.short(firstWeek + i * 7).split(' ').first];

    final steps = Stats.stepSeries(t.steps, days, today).map((v) => v.toDouble()).toList();
    final avg = Stats.movingAverage(steps, 7);
    final meanSteps = steps.isEmpty ? 0 : steps.reduce((a, b) => a + b) / steps.length;
    final stepTrend = Stats.trend(steps);
    final top = MediaQuery.paddingOf(context).top;
    var k = 0;
    Duration next() => Duration(milliseconds: 70 * k++);

    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + 18, 20, 130),
      children: [
        Reveal(
          delay: next(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text('Stats', style: Txt.display(46))),
              SizedBox(
                width: 168,
                child: PillSegments<Range>(
                  values: Range.values,
                  selected: _range,
                  label: (r) => r.label,
                  onChanged: (r) => setState(() => _range = r),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Reveal(
          delay: next(),
          child: Row(
            children: [
              Expanded(
                child: _Tile(value: ((rate ?? 0) * 100).round(), unit: '%', label: 'completion', color: Palette.ember),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Tile(value: perfect, unit: 'days', label: 'perfect', color: Palette.gold),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Tile(value: sessions, unit: '', label: 'workouts', color: Palette.sky),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Reveal(
          delay: next(),
          child: PanelCard(
            glow: Palette.ember,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('Consistency', trailing: Text('26 WEEKS', style: Txt.label(10.5))),
                const SizedBox(height: 14),
                Heatmap(
                  weeks: 26,
                  today: today,
                  score: t.dayScore,
                  describe: (d) {
                    final due = t.habits.where((h) => h.scheduledOn(d)).toList();
                    final hit = due.where((h) => t.isDone(h.id, d)).length;
                    return due.isEmpty
                        ? '${Days.label(d)} · nothing due'
                        : '${Days.label(d)} · $hit of ${due.length} done';
                  },
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
                const Eyebrow('Completion rate'),
                const SizedBox(height: 4),
                _Headline(
                  value: '${((rate ?? 0) * 100).round()}%',
                  note: _range == Range.w4 ? 'day by day' : 'week by week',
                ),
                const SizedBox(height: 8),
                LineChart(
                  values: completion,
                  min: 0,
                  max: 108,
                  format: (v) => '${v.round()}%',
                  label: (i) => _range == Range.w4 ? Days.short(from + i) : 'wk ${Days.short(firstWeek + i * 7)}',
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
                Eyebrow(
                  _minutes ? 'Training minutes' : 'Weekly volume',
                  trailing: SizedBox(
                    width: 136,
                    child: PillSegments<bool>(
                      values: const [false, true],
                      selected: _minutes,
                      height: 30,
                      label: (m) => m ? 'Minutes' : 'Kg',
                      onChanged: (m) => setState(() => _minutes = m),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _Headline(
                  value: _minutes ? '${compact(load.last)} min' : '${compact(load.last)} kg',
                  note: 'this week',
                ),
                const SizedBox(height: 10),
                BarChart(
                  values: load,
                  labels: weekLabels,
                  color: _minutes ? Palette.sky : Palette.ember,
                  format: (v) => compact(v),
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
                Eyebrow(
                  t.stepSource == StepSource.health ? 'Steps · Health Connect' : 'Steps · sample',
                  trailing: stepTrend == null
                      ? null
                      : Text(
                          '${stepTrend >= 0 ? '▲' : '▼'} ${(stepTrend.abs() * 100).round()}%',
                          style: Txt.label(11, color: stepTrend >= 0 ? Palette.volt : Palette.flare),
                        ),
                ),
                const SizedBox(height: 4),
                _Headline(value: grouped(meanSteps), note: 'a day on average'),
                const SizedBox(height: 8),
                LineChart(
                  values: steps,
                  average: avg,
                  goal: t.stepGoal.toDouble(),
                  color: Palette.volt,
                  format: (v) => grouped(v),
                  label: (i) => Days.short(from + i),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const _Key(color: Palette.volt, text: 'Daily'),
                    const SizedBox(width: 14),
                    const _Key(color: Palette.ink, text: '7-day average'),
                    const SizedBox(width: 14),
                    _Key(color: Palette.gold, text: 'Goal ${compact(t.stepGoal)}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.unit, required this.label, required this.color});

  final int value;
  final String unit, label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: .22), Palette.card],
      ),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CountUp(value, style: Txt.display(32)),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 4),
                  child: Text(
                    unit,
                    style: Txt.text(12, weight: FontWeight.w800, color: Palette.ink2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: Txt.label(9.5, color: color)),
      ],
    ),
  );
}

class _Headline extends StatelessWidget {
  const _Headline({required this.value, required this.note});

  final String value, note;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      AnimatedSwitcher(
        duration: Motion.base,
        transitionBuilder: (c, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(a),
            child: c,
          ),
        ),
        child: Text(value, key: ValueKey(value), style: Txt.display(30)),
      ),
      const SizedBox(width: 8),
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          note,
          style: Txt.text(13, weight: FontWeight.w600, color: Palette.ink3),
        ),
      ),
    ],
  );
}

class _Key extends StatelessWidget {
  const _Key({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 3,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 5),
      Text(
        text,
        style: Txt.text(11, weight: FontWeight.w600, color: Palette.ink3),
      ),
    ],
  );
}
