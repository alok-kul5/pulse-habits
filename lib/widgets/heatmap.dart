import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';
import '../data/days.dart';
import '../data/stats.dart';

/// A GitHub-style streak heatmap: one column per week, Monday at the top.
/// Cells pop in as a wave from the oldest week to today, today breathes,
/// and tapping a cell tells you what happened that day.
class Heatmap extends StatefulWidget {
  const Heatmap({
    super.key,
    required this.weeks,
    required this.today,
    required this.score,
    this.color = Palette.ember,
    this.describe,
    this.gap = 3,
  });

  final int weeks;
  final int today;
  final double? Function(int day) score;
  final Color color;
  final String Function(int day)? describe;
  final double gap;

  @override
  State<Heatmap> createState() => _HeatmapState();
}

class _HeatmapState extends State<Heatmap> with TickerProviderStateMixin {
  late final _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  int? _picked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Motion.reduced(context)) {
        _in.value = 1;
      } else {
        _in.forward();
        _beat.repeat();
      }
    });
  }

  @override
  void didUpdateWidget(Heatmap old) {
    super.didUpdateWidget(old);
    if (old.weeks != widget.weeks || old.color != widget.color) {
      _picked = null;
      if (!Motion.reduced(context)) _in.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _beat.dispose();
    super.dispose();
  }

  int get _first => Days.weekStart(widget.today) - (widget.weeks - 1) * 7;

  @override
  Widget build(BuildContext context) {
    final grid = Stats.heatmap(widget.weeks, widget.today, widget.score);
    return LayoutBuilder(
      builder: (context, box) {
        const labelW = 18.0, monthH = 16.0;
        final cell = math.min(22.0, (box.maxWidth - labelW) / widget.weeks - widget.gap);
        final h = monthH + 7 * (cell + widget.gap);
        final w = labelW + widget.weeks * (cell + widget.gap);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final col = ((d.localPosition.dx - labelW) / (cell + widget.gap)).floor();
                final row = ((d.localPosition.dy - monthH) / (cell + widget.gap)).floor();
                if (col < 0 || col >= widget.weeks || row < 0 || row > 6) return;
                final day = _first + col * 7 + row;
                if (day > widget.today) return;
                HapticFeedback.selectionClick();
                setState(() => _picked = _picked == day ? null : day);
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([_in, _beat]),
                builder: (context, _) => CustomPaint(
                  size: Size(w, h),
                  painter: _HeatPainter(
                    grid: grid,
                    first: _first,
                    today: widget.today,
                    cell: cell,
                    gap: widget.gap,
                    labelW: labelW,
                    monthH: monthH,
                    t: _in.value,
                    beat: _beat.value,
                    color: widget.color,
                    picked: _picked,
                    labelStyle: Txt.text(9.5, weight: FontWeight.w700, color: Palette.ink3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Motion.quick,
                    child: Text(
                      _picked == null ? 'Tap a day' : (widget.describe?.call(_picked!) ?? Days.label(_picked!)),
                      key: ValueKey(_picked),
                      style: Txt.text(
                        12.5,
                        weight: FontWeight.w600,
                        color: _picked == null ? Palette.ink3 : Palette.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Text('Less', style: Txt.text(10.5, color: Palette.ink3)),
                const SizedBox(width: 5),
                for (var l = 0; l <= 4; l++)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: Palette.heat(l, widget.color),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                const SizedBox(width: 2),
                Text('More', style: Txt.text(10.5, color: Palette.ink3)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter({
    required this.grid,
    required this.first,
    required this.today,
    required this.cell,
    required this.gap,
    required this.labelW,
    required this.monthH,
    required this.t,
    required this.beat,
    required this.color,
    required this.picked,
    required this.labelStyle,
  });

  final List<List<int>> grid;
  final int first, today;
  final double cell, gap, labelW, monthH, t, beat;
  final Color color;
  final int? picked;
  final TextStyle labelStyle;

  void _text(Canvas canvas, String s, Offset at) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final weeks = grid.length;
    final step = cell + gap;

    // Weekday letters: Mon, Wed, Fri.
    for (final r in [0, 2, 4]) {
      _text(canvas, Days.weekdayLetter[r], Offset(2, monthH + r * step + cell / 2 - 6));
    }
    // Month names over the first week that starts in a new month.
    var lastMonth = -1;
    for (var w = 0; w < weeks; w++) {
      final m = Days.date(first + w * 7).month;
      if (m != lastMonth) {
        if (lastMonth != -1 && w < weeks - 1) _text(canvas, Days.monthShort[m - 1], Offset(labelW + w * step, 0));
        lastMonth = m;
      }
    }

    final radius = Radius.circular(math.max(2, cell * .28));
    for (var w = 0; w < weeks; w++) {
      for (var d = 0; d < 7; d++) {
        final level = grid[w][d];
        if (level == -2) continue; // future
        // A wave: older weeks first, a slight lag down each column.
        final delay = (w / weeks) * .55 + d * .025;
        final p = ((t - delay) / .4).clamp(0.0, 1.0);
        if (p <= 0) continue;
        final s = Motion.spring.transform(p);
        final ctr = Offset(labelW + w * step + cell / 2, monthH + d * step + cell / 2);
        final rect = Rect.fromCenter(center: ctr, width: cell * s, height: cell * s);
        final c = Palette.heat(level, color);
        final day = first + w * 7 + d;
        if (level == 4) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.inflate(1.5), radius),
            Paint()
              ..color = color.withValues(alpha: .35 * p)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          );
        }
        canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), Paint()..color = c.withValues(alpha: p));
        if (day == today) {
          final b = math.sin(beat * math.pi);
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.inflate(1.5 + b * 2.5), Radius.circular(radius.x + 2)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..color = Colors.white.withValues(alpha: (.85 - b * .5) * p),
          );
        }
        if (day == picked) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.inflate(2), Radius.circular(radius.x + 2)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Palette.ink,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.t != t || old.beat != beat || old.picked != picked || old.grid != grid || old.color != color;
}
