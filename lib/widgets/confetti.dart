import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';

/// A one-off burst of confetti from [origin] over the whole screen, with a
/// banner. Played when the last habit of the day is ticked.
void celebrate(BuildContext context, {required Offset origin, String title = 'Perfect day', String? subtitle}) {
  if (Motion.reduced(context)) return;
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Material(
      type: MaterialType.transparency,
      child: _Celebration(origin: origin, title: title, subtitle: subtitle, onDone: () => entry.remove()),
    ),
  );
  overlay.insert(entry);
  HapticFeedback.heavyImpact();
  Future.delayed(const Duration(milliseconds: 140), HapticFeedback.mediumImpact);
  Future.delayed(const Duration(milliseconds: 280), HapticFeedback.lightImpact);
}

class _Celebration extends StatefulWidget {
  const _Celebration({required this.origin, required this.title, required this.subtitle, required this.onDone});

  final Offset origin;
  final String title;
  final String? subtitle;
  final VoidCallback onDone;

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _Bit {
  _Bit(math.Random r)
    : angle = -math.pi / 2 + (r.nextDouble() - .5) * math.pi * 1.3,
      speed = 520 + r.nextDouble() * 760,
      spin = (r.nextDouble() - .5) * 18,
      size = 5 + r.nextDouble() * 7,
      color = [Palette.ember, Palette.flare, Palette.gold, Palette.volt, Palette.sky, Colors.white][r.nextInt(6)],
      round = r.nextBool();

  final double angle, speed, spin, size;
  final Color color;
  final bool round;
}

class _CelebrationState extends State<_Celebration> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();
  final _bits = List.generate(90, (_) => _Bit(math.Random()));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final banner = t < .75 ? Motion.spring.transform((t / .25).clamp(0, 1)) : 1 - ((t - .75) / .25);
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _ConfettiPainter(_bits, t, widget.origin))),
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.paddingOf(context).top + 90,
                child: Opacity(
                  opacity: banner.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: .6 + .4 * banner,
                    child: Column(
                      children: [
                        Text(
                          widget.title,
                          style: Txt.display(46).copyWith(shadows: Palette.glow(Palette.flare, .8, 30)),
                        ),
                        if (widget.subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              widget.subtitle!,
                              style: Txt.text(15, weight: FontWeight.w700, color: Palette.ink2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.bits, this.t, this.origin);

  final List<_Bit> bits;
  final double t;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    final time = t * 2.2; // seconds
    for (final b in bits) {
      final drag = math.exp(-1.6 * time);
      final dist = b.speed * (1 - drag) / 1.6;
      final p = origin + Offset(math.cos(b.angle), math.sin(b.angle)) * dist + Offset(0, 260 * time * time);
      final alpha = (1 - ((t - .6) / .4).clamp(0.0, 1.0));
      if (alpha <= 0) continue;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(b.spin * time);
      final paint = Paint()..color = b.color.withValues(alpha: alpha);
      if (b.round) {
        canvas.drawCircle(Offset.zero, b.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: b.size, height: b.size * .45),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
