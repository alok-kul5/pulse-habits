import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';

/// Flips to true when the splash starts handing over, so screens can play
/// their entrance at the moment the curtain opens.
final introDone = ValueNotifier<bool>(false);

/// Anything tappable: dips under the finger and springs back.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = .96,
    this.haptic = true,
    this.semantics,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final String? semantics;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: widget.semantics,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapCancel: () => _set(false),
          onTapUp: (_) => _set(false),
          onLongPress: widget.onLongPress,
          onTap: enabled
              ? () {
                  if (widget.haptic) HapticFeedback.selectionClick();
                  widget.onTap!();
                }
              : null,
          child: AnimatedScale(
            scale: _down ? widget.scale : 1,
            duration: _down ? const Duration(milliseconds: 90) : Motion.base,
            curve: _down ? Curves.easeOut : Motion.spring,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Rises, fades and un-blurs in after [delay], once the intro has finished.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 28,
    this.duration = Motion.slow,
    this.scale = 1,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;
  final double scale;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration);
  late final _t = CurvedAnimation(parent: _c, curve: Motion.out);

  @override
  void initState() {
    super.initState();
    if (introDone.value) {
      _start();
    } else {
      introDone.addListener(_onIntro);
    }
  }

  void _onIntro() {
    if (introDone.value) {
      introDone.removeListener(_onIntro);
      _start();
    }
  }

  void _start() {
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    introDone.removeListener(_onIntro);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * widget.offset),
            child: Transform.scale(scale: widget.scale + (1 - widget.scale) * v, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A figure that counts to its new value instead of jumping.
class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, required this.style, this.format, this.duration = Motion.chart});

  final num value;
  final TextStyle style;
  final String Function(double)? format;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.toDouble()),
    duration: Motion.of(context, duration),
    curve: Motion.out,
    builder: (context, v, _) => Text(format?.call(v) ?? '${v.round()}', style: style),
  );
}

/// A whole number that slides up or down when it changes, like an odometer.
class RollingNumber extends StatefulWidget {
  const RollingNumber(this.value, {super.key, required this.style});

  final int value;
  final TextStyle style;

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber> {
  late int _prev = widget.value;

  @override
  void didUpdateWidget(RollingNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _prev = old.value;
  }

  @override
  Widget build(BuildContext context) {
    final up = widget.value >= _prev;
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.slow),
      switchInCurve: Motion.spring,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        final incoming = child.key == ValueKey(widget.value);
        final dir = (incoming ? 1.0 : -1.0) * (up ? 1 : -1);
        return ClipRect(
          child: SlideTransition(
            position: Tween(begin: Offset(0, .8 * dir), end: Offset.zero).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
        );
      },
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [...previous, ?current]),
      child: Text('${widget.value}', key: ValueKey(widget.value), style: widget.style),
    );
  }
}

/// The standard surface: a dark card with a hairline and optional glow.
class PanelCard extends StatelessWidget {
  const PanelCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.glow, this.color});

  final Widget child;
  final EdgeInsets padding;
  final Color? glow;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? Palette.card,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Palette.line.withValues(alpha: .7)),
      boxShadow: glow == null ? null : Palette.glow(glow!, .18, 40),
    ),
    child: child,
  );
}

/// Small caps label above a section.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = Palette.ink3, this.trailing});

  final String text;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 3,
        child: Text(
          text.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Txt.label(11, color: color),
        ),
      ),
      if (trailing != null)
        Flexible(
          flex: 4,
          child: Align(alignment: Alignment.centerRight, child: trailing),
        ),
    ],
  );
}

/// "Phone only" tag for things the web demo can't do.
class PhoneOnlyTag extends StatelessWidget {
  const PhoneOnlyTag({super.key, this.text = 'PHONE ONLY'});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Palette.gold.withValues(alpha: .5)),
      color: Palette.gold.withValues(alpha: .08),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.smartphone_rounded, size: 12, color: Palette.gold),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Txt.label(9.5, color: Palette.gold),
          ),
        ),
      ],
    ),
  );
}

/// A segmented control with a gradient pill that springs between options.
class PillSegments<T> extends StatelessWidget {
  const PillSegments({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.height = 36,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final i = values.indexOf(selected);
    final n = values.length;
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: Palette.raised, borderRadius: BorderRadius.circular(height)),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * i / (n - 1), 0),
            duration: Motion.of(context, Motion.slow),
            curve: Motion.spring,
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: Palette.brand,
                  borderRadius: BorderRadius.circular(height),
                  boxShadow: Palette.glow(Palette.flare, .35, 14),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final v in values)
                Expanded(
                  child: Semantics(
                    selected: v == selected,
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(v);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Motion.quick,
                          style: Txt.text(
                            12.5,
                            weight: FontWeight.w800,
                            color: v == selected ? Colors.white : Palette.ink2,
                          ),
                          child: Text(label(v)),
                        ),
                      ),
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

/// The big gradient call to action.
class GlowButton extends StatelessWidget {
  const GlowButton({super.key, required this.label, required this.onTap, this.icon, this.expand = true});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semantics: label,
    child: AnimatedOpacity(
      opacity: onTap == null ? .4 : 1,
      duration: Motion.quick,
      child: Container(
        height: 56,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: Palette.brand,
          borderRadius: BorderRadius.circular(20),
          boxShadow: onTap == null ? null : Palette.glow(Palette.flare, .4, 26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Txt.text(16, weight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A quiet outlined button for secondary actions.
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onTap, this.icon, this.color = Palette.ink});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semantics: label,
    child: Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.line, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, color: color, size: 18), const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Txt.text(14, weight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Shows a short message in a floating capsule.
void toast(BuildContext context, String message, {String? action, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Palette.raised,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      content: Text(message, style: Txt.text(14, weight: FontWeight.w600)),
      action: action == null
          ? null
          : SnackBarAction(label: action, textColor: Palette.ember, onPressed: onAction ?? () {}),
    ),
  );
}
