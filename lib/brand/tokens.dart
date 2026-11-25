import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Colour, type and motion for Pulse. One place, so every screen agrees.
///
/// A dark field the colour of a night run, lit by one hot gradient: ember
/// orange into flare pink. Habits bring their own colours on top.
abstract final class Palette {
  static const night = Color(0xFF0D0A14);
  static const card = Color(0xFF16121F);
  static const raised = Color(0xFF201A2B);
  static const line = Color(0xFF2B2438);
  static const ink = Color(0xFFF7F3FB);
  static const ink2 = Color(0xFFBEB5CC);
  static const ink3 = Color(0xFF7D748C);

  static const ember = Color(0xFFFF5A36);
  static const flare = Color(0xFFFF2D6F);
  static const gold = Color(0xFFFFB443);
  static const volt = Color(0xFFB6F24A);
  static const sky = Color(0xFF55B8FF);

  static const brand = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ember, flare]);

  /// Habit colours, picked per habit. Bright enough to glow on the night field.
  static const hues = [
    Color(0xFFFF5A36), // ember
    Color(0xFF9D7BFF), // violet
    Color(0xFFB6F24A), // volt
    Color(0xFF55B8FF), // sky
    Color(0xFFFFB443), // gold
    Color(0xFF3FE0B5), // mint
    Color(0xFFFF4FA3), // flare pink
    Color(0xFFFF8A5B), // peach
  ];

  static Color hue(int i) => hues[i % hues.length];

  /// Heatmap ramp, level 0 (nothing) to 4 (everything).
  static Color heat(int level, [Color base = ember]) => switch (level) {
    < 0 => const Color(0xFF14101C),
    0 => raised,
    1 => Color.lerp(raised, base, .32)!,
    2 => Color.lerp(raised, base, .58)!,
    3 => Color.lerp(raised, base, .8)!,
    _ => base,
  };

  static List<BoxShadow> glow(Color c, [double alpha = .45, double blur = 24]) => [
    BoxShadow(
      color: c.withValues(alpha: alpha),
      blurRadius: blur,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Bricolage Grotesque for headlines and figures (heavy and tight),
/// Manrope for interface text.
abstract final class Txt {
  /// Off in tests, where nothing may touch the network.
  static bool useGoogleFonts = true;

  static TextStyle display(
    double size, {
    Color color = Palette.ink,
    double height = 1,
    FontWeight weight = FontWeight.w800,
  }) {
    final base = TextStyle(
      fontSize: size,
      height: height,
      letterSpacing: -0.035 * size,
      color: color,
      fontWeight: weight,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return useGoogleFonts ? GoogleFonts.bricolageGrotesque(textStyle: base) : base;
  }

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = Palette.ink,
    double height = 1.35,
    double spacing = 0,
  }) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return useGoogleFonts ? GoogleFonts.manrope(textStyle: base) : base;
  }

  static TextStyle label(double size, {Color color = Palette.ink3}) =>
      text(size, weight: FontWeight.w800, color: color, spacing: 1.4, height: 1.2);
}

/// Motion tokens. Things arrive fast and land with a little bounce, the way
/// a heartbeat kicks. Reduced motion collapses durations to almost nothing.
abstract final class Motion {
  static const quick = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 560);
  static const hero = Duration(milliseconds: 620);
  static const chart = Duration(milliseconds: 900);

  static const out = Cubic(0.16, 1, 0.3, 1); // expo-ish out
  static const inOut = Cubic(0.65, 0, 0.35, 1);
  static const spring = Cubic(0.34, 1.56, 0.64, 1); // overshoot, then settle
  static const soft = Cubic(0.34, 1.25, 0.64, 1); // a smaller overshoot

  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) => reduced(context) ? const Duration(milliseconds: 1) : d;
}

/// 12 400 → "12.4k", 980 → "980".
String compact(num v) {
  if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v.abs() >= 10000) return '${(v / 1000).toStringAsFixed(0)}k';
  if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.round().toString();
}

/// 12345 → "12,345".
String grouped(num v) {
  final s = v.round().abs().toString();
  final b = StringBuffer(v < 0 ? '−' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// 450 → "7:30 am".
String clock(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} ${h < 12 ? 'am' : 'pm'}';
}
