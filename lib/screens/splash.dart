import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../brand/logo.dart';
import '../brand/tokens.dart';
import '../widgets/ui.dart';

/// Opening sequence, about 2.8 s:
///  1. a faint line runs in from the left edge, like a monitor,
///  2. it kicks into one heartbeat and finishes as a tick (two haptic beats),
///  3. shock rings spread from the tick and the wordmark rises,
///  4. the screen gives one last beat and a circle opens from the tick,
///     revealing Today, which starts its entrance at that moment.
class Splash extends StatefulWidget {
  const Splash({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  static const _exitAt = .76;
  static const markSize = 148.0;
  bool _beat1 = false, _beat2 = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
      ..addListener(() {
        final t = _c.value;
        if (t >= .2 && !_beat1) {
          _beat1 = true;
          HapticFeedback.mediumImpact();
        }
        if (t >= .42 && !_beat2) {
          _beat2 = true;
          HapticFeedback.heavyImpact();
        }
        if (t >= _exitAt && !introDone.value) introDone.value = true;
      })
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Motion.reduced(context)) {
        introDone.value = true;
        widget.onDone();
        return;
      }
      _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        // Impatient? Tap to jump to the reveal.
        onTap: () {
          if (_c.value < _exitAt) _c.forward(from: _exitAt);
        },
        child: LayoutBuilder(
          builder: (context, box) {
            final size = box.biggest;
            final markRect = Rect.fromCenter(
              center: size.center(const Offset(0, -46)),
              width: markSize,
              height: markSize,
            );
            final tick = markRect.topLeft + PulseMarkPainter.points.last * (markSize / 128);
            return AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                final exit = Curves.easeInOutCubic.transform(seg(t, _exitAt + .04, 1));
                // One last beat right before the curtain opens.
                final thump = math.sin(seg(t, _exitAt - .04, _exitAt + .06) * math.pi);
                return ClipPath(
                  clipper: _HoleClipper(exit, tick),
                  child: ColoredBox(
                    color: Palette.night,
                    child: Transform.scale(
                      scale: 1 + .045 * thump,
                      child: CustomPaint(
                        painter: _Monitor(t, markRect, tick),
                        child: Stack(
                          children: [
                            Positioned.fromRect(
                              rect: markRect,
                              child: PulseMark(size: markSize, progress: Curves.easeInOut.transform(seg(t, .1, .44))),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: markRect.bottom + 14,
                              child: Column(
                                children: [
                                  _Wordmark(t: seg(t, .4, .66)),
                                  const SizedBox(height: 12),
                                  Opacity(
                                    opacity: Curves.easeOut.transform(seg(t, .56, .7)),
                                    child: Transform.translate(
                                      offset: Offset(0, 10 * (1 - seg(t, .56, .7))),
                                      child: Text(
                                        'HABITS  ·  WORKOUTS  ·  STREAKS',
                                        style: Txt.label(11, color: Palette.ink2.withValues(alpha: .7)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    const word = 'pulse';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < word.length; i++)
          Builder(
            builder: (context) {
              final lt = ((t * 1.6) - i * .12).clamp(0.0, 1.0);
              final y = Motion.spring.transform(lt);
              return ClipRect(
                child: Transform.translate(
                  offset: Offset(0, 64 * (1 - y)),
                  child: Opacity(
                    opacity: lt,
                    child: Text(word[i], style: Txt.display(66, height: 1.12)),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// The monitor line running in from the edge, the rings and the glow.
class _Monitor extends CustomPainter {
  _Monitor(this.t, this.mark, this.tick);

  final double t;
  final Rect mark;
  final Offset tick;

  @override
  void paint(Canvas canvas, Size size) {
    final s = mark.width / 128;
    final start = mark.topLeft + PulseMarkPainter.points.first * s;

    // Lead-in from the left edge, then a faint trail off the right edge.
    final lead = Curves.easeIn.transform(_SplashState.seg(t, 0, .12));
    if (lead > 0) {
      final fadeOut = 1 - _SplashState.seg(t, .55, .75);
      final p = Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            Palette.ember.withValues(alpha: 0),
            Palette.ember.withValues(alpha: .7 * fadeOut),
          ],
        ).createShader(Rect.fromPoints(Offset(0, start.dy), start));
      canvas.drawLine(Offset(0, start.dy), Offset(start.dx * lead, start.dy), p);
    }
    final trail = Curves.easeOut.transform(_SplashState.seg(t, .44, .6));
    if (trail > 0) {
      final fadeOut = 1 - _SplashState.seg(t, .6, .78);
      canvas.drawLine(
        tick,
        Offset(tick.dx + (size.width - tick.dx) * trail, tick.dy - 30 * trail),
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = Palette.flare.withValues(alpha: .35 * fadeOut),
      );
    }

    // Glow behind the mark once the beat lands.
    final g = Curves.easeOut.transform(_SplashState.seg(t, .18, .5));
    if (g > 0) {
      final c = mark.center;
      canvas.drawCircle(
        c,
        260,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Palette.flare.withValues(alpha: .26 * g),
              Palette.ember.withValues(alpha: .08 * g),
              Colors.transparent,
            ],
            stops: const [0, .5, 1],
          ).createShader(Rect.fromCircle(center: c, radius: 260)),
      );
    }

    // Shock rings from the tick.
    for (var k = 0; k < 3; k++) {
      final rt = _SplashState.seg(t, .43 + k * .07, .8 + k * .07);
      if (rt <= 0 || rt >= 1) continue;
      final e = Curves.easeOutCubic.transform(rt);
      canvas.drawCircle(
        tick,
        10 + e * math.max(size.width, size.height) * .6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * (1 - rt) + .4
          ..color = Color.lerp(Palette.flare, Palette.ember, k / 2)!.withValues(alpha: .55 * (1 - rt)),
      );
    }
  }

  @override
  bool shouldRepaint(_Monitor old) => old.t != t;
}

/// Everything except a growing circle around [center].
class _HoleClipper extends CustomClipper<Path> {
  _HoleClipper(this.t, this.center);

  final double t;
  final Offset center;

  @override
  Path getClip(Size size) {
    final full = Path()..addRect(Offset.zero & size);
    if (t <= 0) return full;
    final far = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((c) => (c - center).distance).reduce(math.max);
    final hole = Path()..addOval(Rect.fromCircle(center: center, radius: (far + 10) * t));
    return Path.combine(PathOperation.difference, full, hole);
  }

  @override
  bool shouldReclip(_HoleClipper old) => old.t != t;
}
