import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// The Pulse mark: a heartbeat line whose last beat turns into a tick.
/// [progress] draws the line from left to right (0…1), so the splash can
/// trace it, and a bright head rides the tip while it is drawing.
class PulseMark extends StatelessWidget {
  const PulseMark({super.key, this.size = 96, this.progress = 1, this.tile = false});

  final double size;
  final double progress;

  /// Draw the night tile behind the line, as on the app icon.
  final bool tile;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: PulseMarkPainter(progress: progress, tile: tile),
  );
}

class PulseMarkPainter extends CustomPainter {
  PulseMarkPainter({this.progress = 1, this.tile = false});

  final double progress;
  final bool tile;

  /// The line on a 128 × 128 grid: flat, a beat, then the tick.
  static const points = [
    Offset(18, 68),
    Offset(38, 68),
    Offset(47, 44),
    Offset(58, 88),
    Offset(66, 63),
    Offset(77, 75),
    Offset(108, 41),
  ];

  static Path path(Rect r) {
    final s = r.width / 128;
    final p = Path()..moveTo(r.left + points[0].dx * s, r.top + points[0].dy * s);
    for (final o in points.skip(1)) {
      p.lineTo(r.left + o.dx * s, r.top + o.dy * s);
    }
    return p;
  }

  /// Paints the mark into [r]. Shared with the icon generator.
  static void paintMark(Canvas canvas, Rect r, {double progress = 1, bool tile = false, bool glow = true}) {
    final s = r.width / 128;
    if (tile) {
      final rr = RRect.fromRectAndRadius(r, Radius.circular(30 * s));
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F1830), Palette.night],
          ).createShader(r),
      );
    }
    if (progress <= 0) return;
    final full = path(r);
    final metric = full.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0));
    final shader = ui.Gradient.linear(r.centerLeft + Offset(14 * s, 0), r.centerRight - Offset(14 * s, 0), const [
      Palette.ember,
      Palette.flare,
    ]);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = shader;
    if (glow) {
      canvas.drawPath(
        drawn,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16 * s
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = shader
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 * s)
          ..color = Colors.white.withValues(alpha: .7),
      );
    }
    canvas.drawPath(drawn, stroke);

    // The bright head of the line while it is being drawn.
    if (progress < 1) {
      final tip = metric.getTangentForOffset(metric.length * progress)!.position;
      canvas.drawCircle(
        tip,
        9 * s,
        Paint()
          ..color = Colors.white.withValues(alpha: .9)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * s),
      );
      canvas.drawCircle(tip, 4 * s, Paint()..color = Colors.white);
    }
  }

  @override
  void paint(Canvas canvas, Size size) => paintMark(canvas, Offset.zero & size, progress: progress, tile: tile);

  @override
  bool shouldRepaint(PulseMarkPainter old) => old.progress != progress || old.tile != tile;
}
