import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';

/// Resamples [xs] to [n] points by linear interpolation, so a chart can morph
/// between series of different lengths.
List<double> resample(List<double> xs, int n) {
  if (n <= 0) return const [];
  if (xs.isEmpty) return List.filled(n, 0);
  if (xs.length == n) return List.of(xs);
  if (xs.length == 1 || n == 1) return List.filled(n, xs.last);
  return [
    for (var i = 0; i < n; i++)
      () {
        final x = i * (xs.length - 1) / (n - 1);
        final a = x.floor(), b = math.min(a + 1, xs.length - 1);
        return xs[a] + (xs[b] - xs[a]) * (x - a);
      }(),
  ];
}

/// Keeps what a chart is showing and springs it towards new data. Each point
/// starts a little after the one before it, so changes ripple across.
mixin _Morph<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late final AnimationController morph = AnimationController(vsync: this, duration: Motion.chart);
  List<double> _from = const [], _to = const [];
  double stagger = .35;

  List<double> get target;

  void initMorph() {
    _to = target;
    _from = List.filled(_to.length, 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Motion.reduced(context)) {
        morph.value = 1;
      } else {
        morph.forward(from: 0);
      }
    });
  }

  void updateMorph() {
    final next = target;
    if (_listEq(next, _to)) return;
    _from = resample(current, next.length);
    _to = next;
    if (Motion.reduced(context)) {
      morph.value = 1;
    } else {
      morph.forward(from: 0);
    }
  }

  static bool _listEq(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  double progressAt(int i) {
    final n = _to.length;
    final delay = n <= 1 ? 0.0 : stagger * i / (n - 1);
    return ((morph.value - delay) / (1 - stagger)).clamp(0.0, 1.0);
  }

  List<double> get current => [
    for (var i = 0; i < _to.length; i++)
      ui.lerpDouble(i < _from.length ? _from[i] : 0, _to[i], Motion.spring.transform(progressAt(i)))!,
  ];
}

/// Bars that grow with a spring and morph when the data changes. The last
/// bar (this week) wears the brand gradient. Tap a bar to read it.
class BarChart extends StatefulWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    this.format = compact,
    this.height = 170,
    this.color = Palette.ember,
    this.goal,
  });

  final List<double> values;
  final List<String> labels;
  final String Function(num) format;
  final double height;
  final Color color;
  final double? goal;

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart> with TickerProviderStateMixin, _Morph<BarChart> {
  int? _picked;

  @override
  List<double> get target => widget.values;

  @override
  void initState() {
    super.initState();
    initMorph();
  }

  @override
  void didUpdateWidget(BarChart old) {
    super.didUpdateWidget(old);
    if (old.values.length != widget.values.length) _picked = null;
    updateMorph();
  }

  @override
  void dispose() {
    morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.values.length;
    final top = math.max(widget.values.fold<double>(0, math.max), widget.goal ?? 0);
    final maxV = top <= 0 ? 1.0 : top * 1.12;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        void pick(Offset p) {
          if (n == 0) return;
          final i = (p.dx / (w / n)).floor().clamp(0, n - 1);
          if (i != _picked) HapticFeedback.selectionClick();
          setState(() => _picked = i);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => pick(d.localPosition),
          onHorizontalDragUpdate: (d) => pick(d.localPosition),
          child: AnimatedBuilder(
            animation: morph,
            builder: (context, _) => CustomPaint(
              size: Size(w, widget.height),
              painter: _BarPainter(
                values: current,
                labels: widget.labels,
                maxV: maxV,
                color: widget.color,
                picked: _picked,
                format: widget.format,
                goal: widget.goal,
                labelStyle: Txt.text(10, weight: FontWeight.w700, color: Palette.ink3),
                valueStyle: Txt.text(11.5, weight: FontWeight.w800, color: Palette.ink),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.values,
    required this.labels,
    required this.maxV,
    required this.color,
    required this.picked,
    required this.format,
    required this.goal,
    required this.labelStyle,
    required this.valueStyle,
  });

  final List<double> values;
  final List<String> labels;
  final double maxV;
  final Color color;
  final int? picked;
  final String Function(num) format;
  final double? goal;
  final TextStyle labelStyle, valueStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0) return;
    const bottom = 20.0, topPad = 22.0;
    final chartH = size.height - bottom - topPad;
    final slot = size.width / n;
    final barW = math.min(28.0, slot * .62);

    // Baseline grid.
    final grid = Paint()
      ..color = Palette.line.withValues(alpha: .6)
      ..strokeWidth = 1;
    for (var k = 0; k <= 2; k++) {
      final y = topPad + chartH * k / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (var i = 0; i < n; i++) {
      final v = math.max(0.0, values[i]);
      final h = chartH * (v / maxV);
      final x = slot * i + (slot - barW) / 2;
      final r = Rect.fromLTWH(x, topPad + chartH - h, barW, math.max(h, 0));
      final isLast = i == n - 1;
      final sel = picked == i;
      final rr = RRect.fromRectAndCorners(
        r,
        topLeft: Radius.circular(barW * .38),
        topRight: Radius.circular(barW * .38),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isLast || sel ? [Palette.flare, color] : [color.withValues(alpha: .62), color.withValues(alpha: .18)],
        ).createShader(r.inflate(1));
      if (isLast || sel) {
        canvas.drawRRect(
          rr,
          Paint()
            ..color = Palette.flare.withValues(alpha: .45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      if (h > .5) canvas.drawRRect(rr, paint);

      // Labels, thinned out when there are many bars.
      final every = (n / 7).ceil();
      if (i % every == 0 || isLast) {
        final tp = TextPainter(
          text: TextSpan(text: i < labels.length ? labels[i] : '', style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(slot * i + slot / 2 - tp.width / 2, size.height - bottom + 6));
      }
      if (sel || (picked == null && isLast)) {
        final tp = TextPainter(
          text: TextSpan(text: format(values[i]), style: valueStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        final cx = (slot * i + slot / 2 - tp.width / 2).clamp(0.0, size.width - tp.width);
        tp.paint(canvas, Offset(cx, topPad + chartH - h - tp.height - 4));
      }
    }

    if (goal != null && goal! > 0) {
      final y = topPad + chartH * (1 - goal! / maxV);
      _dash(canvas, Offset(0, y), Offset(size.width, y), Palette.gold.withValues(alpha: .8));
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => true;
}

void _dash(Canvas canvas, Offset a, Offset b, Color c) {
  final p = Paint()
    ..color = c
    ..strokeWidth = 1.4;
  final len = (b - a).distance;
  final dir = (b - a) / len;
  for (var d = 0.0; d < len; d += 9) {
    canvas.drawLine(a + dir * d, a + dir * math.min(d + 5, len), p);
  }
}

/// A line with a glowing gradient area that draws itself in, morphs when
/// the data changes and can be scrubbed with a finger.
class LineChart extends StatefulWidget {
  const LineChart({
    super.key,
    required this.values,
    this.average,
    this.goal,
    this.height = 170,
    this.color = Palette.ember,
    this.format = compact,
    this.label,
    this.min,
    this.max,
  });

  final List<double> values;

  /// A smoother companion line, such as a 7-day average.
  final List<double>? average;
  final double? goal;
  final double height;
  final Color color;
  final String Function(num) format;

  /// Text for a scrubbed point, by index.
  final String Function(int i)? label;
  final double? min, max;

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> with TickerProviderStateMixin, _Morph<LineChart> {
  late final _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  int? _scrub;

  @override
  List<double> get target => [...widget.values, ...?widget.average];

  @override
  void initState() {
    super.initState();
    stagger = .2;
    initMorph();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Motion.reduced(context)) {
        _draw.value = 1;
      } else {
        _draw.forward();
      }
    });
  }

  @override
  void didUpdateWidget(LineChart old) {
    super.didUpdateWidget(old);
    updateMorph();
  }

  @override
  void dispose() {
    morph.dispose();
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.values.length;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        void scrub(Offset p) {
          if (n < 2) return;
          final i = (p.dx / w * (n - 1)).round().clamp(0, n - 1);
          if (i != _scrub) HapticFeedback.selectionClick();
          setState(() => _scrub = i);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => scrub(d.localPosition),
          onHorizontalDragUpdate: (d) => scrub(d.localPosition),
          onHorizontalDragEnd: (_) => setState(() => _scrub = null),
          onTapUp: (_) => Future.delayed(const Duration(milliseconds: 1400), () {
            if (mounted) setState(() => _scrub = null);
          }),
          child: AnimatedBuilder(
            animation: Listenable.merge([morph, _draw]),
            builder: (context, _) {
              final all = current;
              final vals = all.take(n).toList();
              final avg = widget.average == null ? null : all.skip(n).toList();
              return CustomPaint(
                size: Size(w, widget.height),
                painter: _LinePainter(
                  values: vals,
                  average: avg,
                  goal: widget.goal,
                  draw: Curves.easeInOutCubic.transform(_draw.value),
                  color: widget.color,
                  scrub: _scrub,
                  format: widget.format,
                  label: widget.label,
                  minV: widget.min,
                  maxV: widget.max,
                  textStyle: Txt.text(11.5, weight: FontWeight.w800, color: Palette.night),
                  subStyle: Txt.text(10, weight: FontWeight.w700, color: Palette.ink3),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.average,
    required this.goal,
    required this.draw,
    required this.color,
    required this.scrub,
    required this.format,
    required this.label,
    required this.minV,
    required this.maxV,
    required this.textStyle,
    required this.subStyle,
  });

  final List<double> values;
  final List<double>? average;
  final double? goal;
  final double draw;
  final Color color;
  final int? scrub;
  final String Function(num) format;
  final String Function(int)? label;
  final double? minV, maxV;
  final TextStyle textStyle, subStyle;

  /// A smooth curve through the points (Catmull-Rom as cubic Béziers).
  static Path smooth(List<Offset> pts) {
    final p = Path();
    if (pts.isEmpty) return p;
    p.moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i > 0 ? pts[i - 1] : pts[i];
      final p1 = pts[i], p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n < 2) return;
    const topPad = 26.0, bottomPad = 8.0;
    final chartH = size.height - topPad - bottomPad;
    final hi = maxV ?? [...values, ...?average, goal ?? 0].fold<double>(0, math.max) * 1.1;
    final lo = minV ?? 0;
    final span = (hi - lo) <= 0 ? 1 : hi - lo;
    Offset at(int i, double v) =>
        Offset(size.width * i / (n - 1), topPad + chartH * (1 - ((v - lo) / span).clamp(-.05, 1.1)));

    // Grid.
    final grid = Paint()
      ..color = Palette.line.withValues(alpha: .55)
      ..strokeWidth = 1;
    for (var k = 0; k <= 2; k++) {
      final y = topPad + chartH * k / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final pts = [for (var i = 0; i < n; i++) at(i, values[i])];
    final line = smooth(pts);
    final metric = line.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * draw);
    final tip = metric.getTangentForOffset(metric.length * draw)?.position ?? pts.last;

    // Area under the drawn part.
    final area = Path.from(drawn)
      ..lineTo(tip.dx, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .38), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    final shader = ui.Gradient.linear(Offset.zero, Offset(size.width, 0), [color, Palette.flare]);
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = shader,
    );

    if (average != null && average!.length == n) {
      final ap = smooth([for (var i = 0; i < n; i++) at(i, average![i])]);
      final am = ap.computeMetrics().first;
      canvas.drawPath(
        am.extractPath(0, am.length * draw),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = Palette.ink.withValues(alpha: .75),
      );
    }

    if (goal != null) {
      final y = at(0, goal!).dy;
      _dash(canvas, Offset(0, y), Offset(size.width, y), Palette.gold.withValues(alpha: .85));
    }

    // The glowing head while drawing, then a dot on the last point.
    final head = draw < 1 ? tip : pts.last;
    canvas.drawCircle(
      head,
      9,
      Paint()
        ..color = Palette.flare.withValues(alpha: .5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(head, 4.5, Paint()..color = Colors.white);

    // Scrub cursor and bubble.
    if (scrub != null && scrub! < n) {
      final p = pts[scrub!];
      canvas.drawLine(
        Offset(p.dx, topPad - 4),
        Offset(p.dx, size.height),
        Paint()
          ..color = Palette.ink.withValues(alpha: .35)
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(p, 6.5, Paint()..color = Colors.white);
      canvas.drawCircle(p, 3.5, Paint()..color = Palette.flare);
      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(text: format(values[scrub!]), style: textStyle),
            if (label != null)
              TextSpan(
                text: '  ${label!(scrub!)}',
                style: textStyle.copyWith(fontWeight: FontWeight.w600),
              ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final bw = tp.width + 16, bh = tp.height + 8;
      final bx = (p.dx - bw / 2).clamp(0.0, size.width - bw);
      final bubble = RRect.fromRectAndRadius(Rect.fromLTWH(bx, 0, bw, bh), const Radius.circular(10));
      canvas.drawRRect(bubble, Paint()..color = Palette.ink);
      tp.paint(canvas, Offset(bx + 8, 4));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}
