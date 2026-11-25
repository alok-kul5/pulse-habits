import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';
import '../data/stats.dart';
import '../platform/health.dart';
import '../platform/phone.dart';
import '../state/tracker.dart';
import '../widgets/ui.dart';
import 'health_explainer.dart';
import 'routes.dart';

/// Today's steps against the goal, with where the number comes from.
class StepsCard extends StatelessWidget {
  const StepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TrackerScope.of(context);
    final phone = PhoneScope.of(context);
    final steps = t.stepsToday;
    final week = Stats.stepSeries(t.steps, 7, t.today);
    return ValueListenableBuilder<HealthStatus>(
      valueListenable: phone.healthStatus,
      builder: (context, status, _) {
        final live = t.stepSource == StepSource.health;
        return PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(
                'Steps',
                trailing: live
                    ? const _Source(text: 'HEALTH CONNECT', color: Palette.volt)
                    : (status == HealthStatus.unsupported
                          ? const PhoneOnlyTag(text: 'SAMPLE · HEALTH CONNECT ON PHONE')
                          : const _Source(text: 'SAMPLE', color: Palette.ink3)),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CountUp(steps, style: Txt.display(40), format: (v) => grouped(v)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '/ ${grouped(t.stepGoal)}',
                      style: Txt.text(14, weight: FontWeight.w700, color: Palette.ink3),
                    ),
                  ),
                  const Spacer(),
                  _Spark(values: week, goal: t.stepGoal),
                ],
              ),
              const SizedBox(height: 12),
              _GoalBar(value: steps / t.stepGoal),
              if (status == HealthStatus.denied || status == HealthStatus.notInstalled) ...[
                const SizedBox(height: 14),
                GhostButton(
                  label: status == HealthStatus.denied ? 'Use my real steps' : 'Get Health Connect',
                  icon: Icons.favorite_rounded,
                  color: Palette.flare,
                  onTap: () => Navigator.of(context).push(riseRoute(const HealthExplainer())),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Source extends StatelessWidget {
  const _Source({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: Palette.glow(color, .8, 6)),
      ),
      const SizedBox(width: 6),
      Text(text, style: Txt.label(10, color: color)),
    ],
  );
}

class _GoalBar extends StatelessWidget {
  const _GoalBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.clamp(0, 1)),
    duration: Motion.of(context, const Duration(milliseconds: 1200)),
    curve: Motion.soft,
    builder: (context, v, _) => Container(
      height: 12,
      decoration: BoxDecoration(color: Palette.raised, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: v.clamp(0.02, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Palette.volt, Palette.gold]),
            borderRadius: BorderRadius.circular(8),
            boxShadow: Palette.glow(Palette.volt, .35, 10),
          ),
        ),
      ),
    ),
  );
}

/// Seven tiny bars, the last week of steps.
class _Spark extends StatelessWidget {
  const _Spark({required this.values, required this.goal});

  final List<int> values;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final top = [...values, goal].reduce((a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: top == 0 ? 0 : values[i] / top),
              duration: Motion.of(context, Duration(milliseconds: 700 + i * 70)),
              curve: Motion.spring,
              builder: (context, v, _) => Container(
                width: 7,
                height: 40 * v.clamp(0.05, 1.1),
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: values[i] >= goal ? Palette.volt : Palette.volt.withValues(alpha: .35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
