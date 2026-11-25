import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';

/// The check-off button. Ticking it is the best moment in the app:
/// the ring sweeps round, the colour blooms out from the centre with a
/// bounce, the tick draws itself, a shock ring and a burst of sparks fly
/// out, and you feel two beats of haptics. Unticking just drains it.
class CheckOrb extends StatefulWidget {
  const CheckOrb({super.key, required this.done, required this.color, required this.onTap, this.size = 46, this.label});

  final bool done;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final String? label;

  @override
  State<CheckOrb> createState() => _CheckOrbState();
}

class _CheckOrbState extends State<CheckOrb> with TickerProviderStateMixin {
  late final _tick = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: widget.done ? 1 : 0,
  );
  late final _drain = AnimationController(vsync: this, duration: const Duration(milliseconds: 260), value: 0);
  bool _down = false;

  @override
  void didUpdateWidget(CheckOrb old) {
    super.didUpdateWidget(old);
    if (old.done == widget.done) return;
    if (Motion.reduced(context)) {
      _tick.value = widget.done ? 1 : 0;
      return;
    }
    if (widget.done) {
      _drain.value = 0;
      _tick.forward(from: 0);
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 170), HapticFeedback.lightImpact);
    } else {
      _drain.forward(from: 0).whenComplete(() {
        if (mounted && !widget.done) {
          _tick.value = 0;
          _drain.value = 0;
        }
      });
    }
  }

  @override
  void dispose() {
    _tick.dispose();
    _drain.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final burst = widget.size * 2.4;
    return Semantics(
      button: true,
      checked: widget.done,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down ? .86 : 1,
            duration: _down ? const Duration(milliseconds: 90) : Motion.base,
            curve: _down ? Curves.easeOut : Motion.spring,
            child: SizedBox.square(
              dimension: widget.size,
              child: OverflowBox(
                maxWidth: burst,
                maxHeight: burst,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_tick, _drain]),
                  builder: (context, _) => CustomPaint(
                    size: Size.square(burst),
                    painter: _OrbPainter(
                      t: _tick.value,
                      drain: _drain.value,
                      color: widget.color,
                      radius: widget.size / 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.t, required this.drain, required this.color, required this.radius});

  final double t, drain;
  final Color color;
  final double radius;

  static double seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = radius - 2;
    final fade = 1 - drain;

    // Track.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Palette.line,
    );
    if (t <= 0) return;

    // 1. The ring sweeps round.
    final sweep = Curves.easeOutCubic.transform(seg(t, 0, .32));
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: fade),
    );

    // 2. Colour blooms out from the centre, overshooting a little.
    final bloom = Motion.spring.transform(seg(t, .18, .62));
    if (bloom > 0) {
      canvas.drawCircle(
        c,
        r * 1.05 * bloom,
        Paint()
          ..color = color.withValues(alpha: .55 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(c, (r + 1) * bloom.clamp(0, 1.12), Paint()..color = color.withValues(alpha: fade));
    }

    // 3. The tick draws itself.
    final draw = Curves.easeOutCubic.transform(seg(t, .34, .66));
    if (draw > 0) {
      final s = r / 20;
      final p = Path()
        ..moveTo(c.dx - 8.5 * s, c.dy + .5 * s)
        ..lineTo(c.dx - 2.5 * s, c.dy + 6.5 * s)
        ..lineTo(c.dx + 9 * s, c.dy - 6 * s);
      final m = p.computeMetrics().first;
      canvas.drawPath(
        m.extractPath(0, m.length * draw),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.6 * s
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Palette.night.withValues(alpha: fade),
      );
    }

    if (drain > 0) return;

    // 4. A shock ring and sparks fly out.
    final shock = seg(t, .3, .8);
    if (shock > 0 && shock < 1) {
      final e = Curves.easeOutCubic.transform(shock);
      canvas.drawCircle(
        c,
        r + e * r * 1.3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - e) + .3
          ..color = color.withValues(alpha: .7 * (1 - e)),
      );
    }
    final fly = seg(t, .3, 1);
    if (fly > 0 && fly < 1) {
      final e = Curves.easeOutCubic.transform(fly);
      const n = 10;
      for (var i = 0; i < n; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / n + (i.isEven ? 0 : .22);
        final dist = r + (i.isEven ? 1.1 : .75) * r * e;
        final len = 7 * (1 - e) + 1;
        final dir = Offset(math.cos(a), math.sin(a));
        final p0 = c + dir * dist;
        canvas.drawLine(
          p0,
          p0 + dir * len,
          Paint()
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..color = (i % 3 == 0 ? Colors.white : color).withValues(alpha: 1 - e),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t || old.drain != drain || old.color != color;
}
