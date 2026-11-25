import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';

/// A page that the habit's tile flies into (Hero) while the rest fades up.
Route<T> heroRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: Motion.hero,
  reverseTransitionDuration: const Duration(milliseconds: 420),
  pageBuilder: (context, a, b) => page,
  transitionsBuilder: (context, a, b, child) {
    final t = CurvedAnimation(parent: a, curve: Motion.out, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(t),
        child: child,
      ),
    );
  },
);

/// A plain full-screen page that rises in.
Route<T> riseRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: Motion.slow,
  reverseTransitionDuration: Motion.base,
  pageBuilder: (context, a, b) => page,
  transitionsBuilder: (context, a, b, child) {
    final t = CurvedAnimation(parent: a, curve: Motion.out);
    return FadeTransition(
      opacity: t,
      child: ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(t), child: child),
    );
  },
);

/// Dark bottom sheet with a grabber that drags down to close.
Future<T?> showPulseSheet<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: Colors.black.withValues(alpha: .6),
  sheetAnimationStyle: const AnimationStyle(
    duration: Duration(milliseconds: 460),
    reverseDuration: Duration(milliseconds: 260),
    curve: Motion.out,
  ),
  builder: (context) => Container(
    decoration: const BoxDecoration(
      color: Palette.card,
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      border: Border(top: BorderSide(color: Palette.line)),
    ),
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 5,
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          decoration: BoxDecoration(color: Palette.line, borderRadius: BorderRadius.circular(3)),
        ),
        Flexible(child: builder(context)),
      ],
    ),
  ),
);
