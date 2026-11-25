import 'package:home_widget/home_widget.dart';
import 'package:material_ui/material_ui.dart';

import '../brand/logo.dart';
import '../brand/tokens.dart';
import '../platform/health.dart';
import '../platform/phone.dart';
import '../platform/reminders.dart';
import '../platform/widget_sync.dart';
import '../state/tracker.dart';
import '../widgets/habit_card.dart';
import '../widgets/ui.dart';
import '../widgets/widget_preview.dart';
import 'habit_sheet.dart';
import 'health_explainer.dart';
import 'routes.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TrackerScope.of(context);
    final phone = PhoneScope.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final totalTicks = t.done.values.fold(0, (a, s) => a + s.length);
    var k = 0;
    Duration next() => Duration(milliseconds: 60 * k++);

    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + 18, 20, 130),
      children: [
        Reveal(
          delay: next(),
          child: Row(
            children: [
              const PulseMark(size: 58, tile: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You', style: Txt.display(40)),
                    Text(
                      '$totalTicks ticks · ${t.workouts.length} workouts · all on this device',
                      style: Txt.text(13, weight: FontWeight.w600, color: Palette.ink3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Reveal(
          delay: next(),
          child: _SampleCard(t: t),
        ),
        const SizedBox(height: 22),
        Reveal(
          delay: next(),
          child: Eyebrow('Home-screen widget', trailing: WidgetSync.platformSupported ? null : const PhoneOnlyTag()),
        ),
        const SizedBox(height: 10),
        Reveal(delay: next(), child: const WidgetPreview()),
        const SizedBox(height: 10),
        Reveal(
          delay: next(),
          child: WidgetSync.platformSupported
              ? Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Today\'s habits, your streak and seven weeks of heat. Tap a habit on it to tick it.',
                        style: Txt.text(13, color: Palette.ink2, height: 1.4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GhostButton(
                      label: 'Add',
                      icon: Icons.add_to_home_screen_rounded,
                      onTap: () async {
                        final ok = await HomeWidget.isRequestPinWidgetSupported() ?? false;
                        if (ok) {
                          await HomeWidget.requestPinWidget(androidName: WidgetSync.provider);
                        } else if (context.mounted) {
                          toast(context, 'Long-press your home screen, then Widgets → Pulse');
                        }
                      },
                    ),
                  ],
                )
              : Text(
                  'A native Android widget (Kotlin, through home_widget): today\'s habits, the streak and seven weeks of heat, ticked from the home screen. It lives on Android; this is what it shows.',
                  style: Txt.text(13, color: Palette.ink2, height: 1.4),
                ),
        ),
        const SizedBox(height: 24),
        Reveal(
          delay: next(),
          child: Eyebrow('Steps', trailing: Health.platformSupported ? null : const PhoneOnlyTag()),
        ),
        const SizedBox(height: 10),
        Reveal(
          delay: next(),
          child: ValueListenableBuilder<HealthStatus>(
            valueListenable: phone.healthStatus,
            builder: (context, s, _) => _Row(
              icon: Icons.favorite_rounded,
              color: Palette.volt,
              title: 'Health Connect',
              subtitle: switch (s) {
                HealthStatus.unsupported => 'Android only. The web demo uses sample steps.',
                HealthStatus.notInstalled => 'Not installed on this phone',
                HealthStatus.denied => 'Not allowed yet. Pulse uses sample steps.',
                HealthStatus.granted => 'Reading daily steps, read-only',
              },
              onTap: () => Navigator.of(context).push(riseRoute(const HealthExplainer())),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Reveal(
          delay: next(),
          child: Eyebrow(
            'Reminders',
            trailing: Reminders.platformSupported ? const _NotifySwitch() : const PhoneOnlyTag(),
          ),
        ),
        const SizedBox(height: 10),
        for (final h in t.habits)
          Reveal(
            delay: next(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Pressable(
                scale: .98,
                semantics: 'Reminder for ${h.name}',
                onTap: () => showPulseSheet(context, (_) => HabitSheet(habit: h)),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Palette.card, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      HabitTile(habit: h, size: 36, hero: false),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          h.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Txt.text(14.5, weight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        h.reminder == null ? 'Off' : clock(h.reminder!),
                        style: Txt.text(
                          14,
                          weight: FontWeight.w800,
                          color: h.reminder == null ? Palette.ink3 : Palette.gold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: Palette.ink3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (!Reminders.platformSupported)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Times are saved here; the notifications themselves fire on Android.',
              style: Txt.text(12.5, color: Palette.ink3),
            ),
          ),
        const SizedBox(height: 24),
        Reveal(delay: next(), child: const Eyebrow('Goals')),
        const SizedBox(height: 10),
        Reveal(
          delay: next(),
          child: _Stepper(
            title: 'Workouts a week',
            value: '${t.weeklyGoal}',
            onMinus: () => t.setWeeklyGoal(t.weeklyGoal - 1),
            onPlus: () => t.setWeeklyGoal(t.weeklyGoal + 1),
          ),
        ),
        const SizedBox(height: 8),
        Reveal(
          delay: next(),
          child: _Stepper(
            title: 'Steps a day',
            value: grouped(t.stepGoal),
            onMinus: () => t.setStepGoal(t.stepGoal - 500),
            onPlus: () => t.setStepGoal(t.stepGoal + 500),
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: Text(
            'Pulse 1.0 · offline-first, no account, no server',
            style: Txt.text(12, weight: FontWeight.w600, color: Palette.ink3),
          ),
        ),
      ],
    );
  }
}

class _SampleCard extends StatelessWidget {
  const _SampleCard({required this.t});

  final Tracker t;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: t.sample ? LinearGradient(colors: [Palette.gold.withValues(alpha: .18), Palette.card]) : null,
      color: t.sample ? null : Palette.card,
      border: Border.all(color: t.sample ? Palette.gold.withValues(alpha: .4) : Palette.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.sample ? 'This is sample data' : 'Your own data', style: Txt.text(16, weight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          t.sample
              ? 'Six months of made-up habits, workouts and steps, so every chart has something to show. Start fresh when you\'re ready.'
              : 'Want to look around with a full history? Load the sample. It replaces what is here.',
          style: Txt.text(13.5, color: Palette.ink2, height: 1.4),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: t.sample
              ? GlowButton(
                  label: 'Start fresh',
                  expand: false,
                  icon: Icons.restart_alt_rounded,
                  onTap: () async {
                    final yes = await _confirm(
                      context,
                      'Start fresh?',
                      'This deletes the sample history. It can be loaded again later.',
                    );
                    if (yes) t.startFresh();
                  },
                )
              : GhostButton(
                  label: 'Load sample data',
                  icon: Icons.auto_awesome_rounded,
                  onTap: () async {
                    final yes = await _confirm(
                      context,
                      'Replace your data?',
                      'Your habits and workouts will be replaced by the sample.',
                    );
                    if (yes) t.loadSample();
                  },
                ),
        ),
      ],
    ),
  );

  static Future<bool> _confirm(BuildContext context, String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Palette.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: Text(title, style: Txt.display(24)),
          content: Text(body, style: Txt.text(14, color: Palette.ink2)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: Txt.text(14, weight: FontWeight.w700, color: Palette.ink2),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Continue',
                style: Txt.text(14, weight: FontWeight.w800, color: Palette.ember),
              ),
            ),
          ],
        ),
      ) ??
      false;
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: .98,
    semantics: title,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Palette.card, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Txt.text(15, weight: FontWeight.w800)),
                Text(subtitle, style: Txt.text(12.5, color: Palette.ink3)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Palette.ink3),
        ],
      ),
    ),
  );
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.title, required this.value, required this.onMinus, required this.onPlus});

  final String title, value;
  final VoidCallback onMinus, onPlus;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
    decoration: BoxDecoration(color: Palette.card, borderRadius: BorderRadius.circular(20)),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Txt.text(14.5, weight: FontWeight.w700)),
        ),
        IconButton(
          onPressed: onMinus,
          tooltip: 'Less',
          icon: const Icon(Icons.remove_rounded, color: Palette.ink2),
        ),
        SizedBox(
          width: 64,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: Txt.text(16, weight: FontWeight.w800),
          ),
        ),
        IconButton(
          onPressed: onPlus,
          tooltip: 'More',
          icon: const Icon(Icons.add_rounded, color: Palette.ink2),
        ),
      ],
    ),
  );
}

/// Asks for the notification permission when reminders exist but Android
/// hasn't been allowed to show them yet.
class _NotifySwitch extends StatefulWidget {
  const _NotifySwitch();

  @override
  State<_NotifySwitch> createState() => _NotifySwitchState();
}

class _NotifySwitchState extends State<_NotifySwitch> {
  bool? _on;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PhoneScope.of(context).reminders.enabled().then((v) {
      if (mounted) setState(() => _on = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_on != false) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () async {
        final v = await PhoneScope.of(context).reminders.requestPermission();
        if (mounted) setState(() => _on = v);
      },
      child: Text('TURN ON NOTIFICATIONS', style: Txt.label(10.5, color: Palette.ember)),
    );
  }
}
