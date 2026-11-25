import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';
import '../platform/health.dart';
import '../platform/phone.dart';
import '../state/tracker.dart';
import '../widgets/ui.dart';

/// Says plainly what Pulse wants from Health Connect before Android asks.
/// Also the page Health Connect opens from "Why does Pulse need this?".
class HealthExplainer extends StatefulWidget {
  const HealthExplainer({super.key});

  @override
  State<HealthExplainer> createState() => _HealthExplainerState();
}

class _HealthExplainerState extends State<HealthExplainer> {
  bool _busy = false;

  Future<void> _go() async {
    final phone = PhoneScope.of(context);
    final tracker = TrackerScope.read(context);
    final status = await phone.refreshHealth();
    if (status == HealthStatus.unsupported) return;
    if (status == HealthStatus.notInstalled) {
      await phone.health.install();
      return;
    }
    setState(() => _busy = true);
    final ok = status == HealthStatus.granted || await phone.health.request();
    await phone.refreshHealth();
    var found = false;
    if (ok) {
      final steps = await phone.health.steps(182);
      found = steps.values.any((v) => v > 0);
      if (found) tracker.setHealthSteps(steps);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop();
      toast(
        context,
        found
            ? 'Steps now come from Health Connect'
            : 'Connected. No steps recorded yet, so sample steps stay until there are.',
      );
    } else {
      toast(context, 'No steps access. You can allow it later in Health Connect.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final supported = Health.platformSupported;
    final top = MediaQuery.paddingOf(context).top;
    var k = 0;
    Duration next() => Duration(milliseconds: 90 * k++);
    return Scaffold(
      backgroundColor: Palette.night,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            right: -80,
            child: IgnorePointer(
              child: Container(
                height: 440,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Palette.volt.withValues(alpha: .16),
                      Palette.flare.withValues(alpha: .05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          ListView(
            padding: EdgeInsets.fromLTRB(24, top + 12, 24, 40),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded, color: Palette.ink2),
                  tooltip: 'Close',
                ),
              ),
              const SizedBox(height: 16),
              Reveal(
                delay: next(),
                scale: .8,
                child: const Center(child: _Badge()),
              ),
              const SizedBox(height: 28),
              Reveal(
                delay: next(),
                child: Text(
                  'Your steps,\nfrom Health Connect',
                  textAlign: TextAlign.center,
                  style: Txt.display(34, height: 1.05),
                ),
              ),
              const SizedBox(height: 12),
              Reveal(
                delay: next(),
                child: Text(
                  'Pulse can chart your real daily steps next to your habits. Android will ask you first. Here is exactly what that means.',
                  textAlign: TextAlign.center,
                  style: Txt.text(15, color: Palette.ink2, height: 1.45),
                ),
              ),
              const SizedBox(height: 28),
              for (final (icon, title, body) in const [
                (
                  Icons.directions_walk_rounded,
                  'Steps only',
                  'Pulse asks for one permission: read steps. No heart rate, sleep, weight or location.',
                ),
                (
                  Icons.visibility_rounded,
                  'Read, never write',
                  'Pulse doesn\'t add, change or delete anything in Health Connect.',
                ),
                (
                  Icons.phonelink_lock_rounded,
                  'Stays on this phone',
                  'No account, no server, no upload. Step counts are kept with your habits on the device.',
                ),
                (
                  Icons.toggle_on_rounded,
                  'Yours to undo',
                  'Turn it off any time in Health Connect. Pulse falls back to logging without steps.',
                ),
              ])
                Reveal(
                  delay: next(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: Palette.raised, borderRadius: BorderRadius.circular(14)),
                          child: Icon(icon, color: Palette.volt, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: Txt.text(15.5, weight: FontWeight.w800)),
                              const SizedBox(height: 3),
                              Text(body, style: Txt.text(13.5, color: Palette.ink2, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Reveal(
                delay: next(),
                child: supported
                    ? Column(
                        children: [
                          GlowButton(
                            label: _busy ? 'Waiting for Health Connect…' : 'Continue',
                            icon: Icons.favorite_rounded,
                            onTap: _busy ? null : _go,
                          ),
                          const SizedBox(height: 10),
                          GhostButton(label: 'Not now', onTap: () => Navigator.of(context).maybePop()),
                        ],
                      )
                    : PanelCard(
                        child: Row(
                          children: [
                            const Icon(Icons.smartphone_rounded, color: Palette.gold),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Health Connect is part of Android, so this works in the Android app, not in the browser. The web demo charts sample steps.',
                                style: Txt.text(13.5, color: Palette.ink2, height: 1.4),
                              ),
                            ),
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

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) => Container(
    width: 112,
    height: 112,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(colors: [Palette.volt, Color(0xFF3FE0B5)]),
      boxShadow: Palette.glow(Palette.volt, .5, 40),
    ),
    child: const Icon(Icons.directions_walk_rounded, size: 58, color: Palette.night),
  );
}
