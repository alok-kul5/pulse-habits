import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';
import '../data/days.dart';
import '../data/models.dart';
import '../state/tracker.dart';
import '../widgets/confetti.dart';
import '../widgets/habit_card.dart';
import '../widgets/ring.dart';
import '../widgets/ui.dart';
import 'habit_detail.dart';
import 'habit_sheet.dart';
import 'routes.dart';
import 'shell.dart';
import 'steps_card.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  /// The day being shown. Null means today; past days can be filled in late.
  int? _day;

  void _toggle(Tracker t, Habit h, int day, Offset orb) {
    final now = t.toggle(h.id, day);
    if (!now) return;
    final due = t.habits.where((x) => x.scheduledOn(day)).toList();
    if (due.isNotEmpty && due.every((x) => t.isDone(x.id, day))) {
      final s = t.perfectStreak.current;
      celebrate(
        context,
        origin: orb,
        title: 'Perfect day',
        subtitle: day == t.today ? (s > 1 ? '$s days in a row' : 'Every habit, done') : Days.label(day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = TrackerScope.of(context);
    final today = t.today;
    final day = _day ?? today;
    final due = t.habits.where((h) => h.scheduledOn(day)).toList();
    final off = t.habits.where((h) => !h.scheduledOn(day) && h.createdDay <= day).toList();
    final doneCount = due.where((h) => t.isDone(h.id, day)).length;
    final top = MediaQuery.paddingOf(context).top;
    final date = Days.date(day);

    var k = 0;
    Duration next() => Duration(milliseconds: 60 * k++);

    return Stack(
      children: [
        // An ember glow bleeding in from the top right corner.
        Positioned(
          top: -160,
          right: -140,
          child: IgnorePointer(
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Palette.flare.withValues(alpha: .22),
                    Palette.ember.withValues(alpha: .06),
                    Colors.transparent,
                  ],
                ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Days.monthLong[date.month - 1].toUpperCase()} ${date.day}',
                          style: Txt.label(12, color: Palette.ember),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            day == today ? 'Today' : Days.relative(day, today).split(' ').first,
                            style: Txt.display(46),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Pressable(
                    semantics: 'New habit',
                    onTap: () => showPulseSheet(context, (_) => const HabitSheet()),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: Palette.brand,
                        shape: BoxShape.circle,
                        boxShadow: Palette.glow(Palette.flare, .5, 22),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Reveal(
              delay: next(),
              scale: .94,
              child: _Hero(done: doneCount, due: due.length, day: day),
            ),
            const SizedBox(height: 16),
            Reveal(
              delay: next(),
              child: _WeekStrip(selected: day, onPick: (d) => setState(() => _day = d == today ? null : d)),
            ),
            const SizedBox(height: 24),
            Reveal(
              delay: next(),
              child: Eyebrow(
                day == today ? 'Due today' : 'Due ${Days.label(day)}',
                trailing: day == today
                    ? Text('$doneCount / ${due.length}', style: Txt.label(11, color: Palette.ink2))
                    : GestureDetector(
                        onTap: () => setState(() => _day = null),
                        child: Text('BACK TO TODAY', style: Txt.label(11, color: Palette.ember)),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            if (t.habits.isEmpty) Reveal(delay: next(), child: const _Empty()),
            for (final h in due)
              Padding(
                key: ValueKey('due-${h.id}'),
                padding: const EdgeInsets.only(bottom: 10),
                child: Reveal(
                  delay: next(),
                  child: HabitCard(
                    habit: h,
                    done: t.isDone(h.id, day),
                    streak: t.streakOf(h).current,
                    onToggle: (orb) => _toggle(t, h, day, orb),
                    onOpen: () => Navigator.of(context).push(heroRoute(HabitDetail(habitId: h.id))),
                  ),
                ),
              ),
            if (off.isNotEmpty) ...[
              const SizedBox(height: 14),
              Reveal(delay: next(), child: const Eyebrow('Not scheduled')),
              const SizedBox(height: 12),
              for (final h in off)
                Padding(
                  key: ValueKey('off-${h.id}'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Reveal(
                    delay: next(),
                    child: HabitCard(
                      habit: h,
                      dim: !t.isDone(h.id, day),
                      done: t.isDone(h.id, day),
                      streak: t.streakOf(h).current,
                      onToggle: (orb) => _toggle(t, h, day, orb),
                      onOpen: () => Navigator.of(context).push(heroRoute(HabitDetail(habitId: h.id))),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 14),
            Reveal(delay: next(), child: const StepsCard()),
          ],
        ),
      ],
    );
  }
}

/// The big ring: how much of the day is done, and the perfect-day streak.
class _Hero extends StatelessWidget {
  const _Hero({required this.done, required this.due, required this.day});

  final int done, due, day;

  @override
  Widget build(BuildContext context) {
    final t = TrackerScope.of(context);
    final streak = t.perfectStreak;
    final week = t.weekRate;
    final allDone = due > 0 && done == due;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1A2E), Color(0xFF1A1324), Palette.card],
        ),
        border: Border.all(color: Palette.flare.withValues(alpha: .25)),
        boxShadow: Palette.glow(Palette.flare, .12, 50),
      ),
      child: Row(
        children: [
          ProgressRing(
            value: due == 0 ? 0 : done / due,
            size: 146,
            stroke: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RollingNumber(done, style: Txt.display(44)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('/$due', style: Txt.display(20, color: Palette.ink3)),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: Motion.base,
                  child: Text(
                    allDone ? 'ALL DONE' : 'DONE',
                    key: ValueKey(allDone),
                    style: Txt.label(10, color: allDone ? Palette.gold : Palette.ink3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (r) =>
                          const LinearGradient(colors: [Palette.gold, Palette.ember]).createShader(r),
                      child: const Icon(Icons.local_fire_department_rounded, size: 34, color: Colors.white),
                    ),
                    const SizedBox(width: 2),
                    RollingNumber(streak.current, style: Txt.display(40)),
                  ],
                ),
                Text(
                  'day perfect streak',
                  style: Txt.text(13, weight: FontWeight.w700, color: Palette.ink2),
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: Palette.line),
                const SizedBox(height: 12),
                _Mini(label: 'Best', value: '${streak.best} days'),
                const SizedBox(height: 6),
                _Mini(label: 'This week', value: week == null ? '—' : '${(week * 100).round()}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value});

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

/// This week, Monday to Sunday. Each day is a small ring of how much got done.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selected, required this.onPick});

  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final t = TrackerScope.of(context);
    final start = Days.weekStart(t.today);
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(
              builder: (context) {
                final d = start + i;
                final future = d > t.today;
                final sel = d == selected;
                final score = future ? null : t.dayScore(d);
                return Pressable(
                  onTap: future ? null : () => onPick(d),
                  semantics: Days.label(d),
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.base),
                    curve: Motion.out,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: sel ? Palette.raised : Colors.transparent,
                      border: Border.all(color: sel ? Palette.flare.withValues(alpha: .6) : Colors.transparent),
                    ),
                    child: Opacity(
                      opacity: future ? .35 : 1,
                      child: Column(
                        children: [
                          Text(Days.weekdayLetter[i], style: Txt.label(10.5, color: sel ? Palette.ink : Palette.ink3)),
                          const SizedBox(height: 6),
                          ProgressRing(
                            value: score ?? 0,
                            size: 36,
                            stroke: 3.5,
                            colors: score == 1
                                ? const [Palette.gold, Palette.ember, Palette.gold]
                                : const [Palette.ember, Palette.flare, Palette.ember],
                            child: Text(
                              '${Days.date(d).day}',
                              style: Txt.text(11.5, weight: FontWeight.w800, color: sel ? Palette.ink : Palette.ink2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => PanelCard(
    child: Column(
      children: [
        const SizedBox(height: 8),
        Text('A clean slate', style: Txt.display(26)),
        const SizedBox(height: 6),
        Text(
          'Add the first thing you want to do every day. Small is good.',
          textAlign: TextAlign.center,
          style: Txt.text(14, color: Palette.ink2),
        ),
        const SizedBox(height: 16),
        GlowButton(
          label: 'New habit',
          icon: Icons.add_rounded,
          onTap: () => showPulseSheet(context, (_) => const HabitSheet()),
        ),
        const SizedBox(height: 8),
        GhostButton(label: 'Or explore sample data', onTap: () => Shell.tab.value = 3),
      ],
    ),
  );
}
