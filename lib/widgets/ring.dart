import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';

/// A progress ring with a gradient stroke and a glowing head. The value
/// springs to its target, so ticking a habit kicks the ring forward.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 180,
    this.stroke = 16,
    this.colors = const [Palette.ember, Palette.flare, Palette.ember],
    this.child,
    this.track = Palette.raised,
  });

  final double value;
  final double size;
  final double stroke;
  final List<Color> colors;
  final Color track;
  final Widget? child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.clamp(0, 1)),
    duration: Motion.of(context, const Duration(milliseconds: 1100)),
    curve: Motion.soft,
    builder: (context, v, child) => CustomPaint(
      size: Size.square(size),
      painter: _RingPainter(v, stroke, colors, track),
      child: SizedBox.square(
        dimension: size,
        child: Center(child: child),
      ),
    ),
    child: child,
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.stroke, this.colors, this.track);

  final double v;
  final double stroke;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - stroke / 2 - 4;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (v <= 0.001) return;
    final sweep = 2 * math.pi * v.clamp(0.0, 1.06);
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      colors: colors,
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);
    // Glow under the arc.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 6
        ..strokeCap = StrokeCap.round
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
    // A bright head on the arc's tip.
    final a = -math.pi / 2 + sweep;
    final tip = c + Offset(math.cos(a), math.sin(a)) * r;
    canvas.drawCircle(tip, stroke * .32, Paint()..color = Colors.white.withValues(alpha: .92));
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v || old.colors != colors;
}
