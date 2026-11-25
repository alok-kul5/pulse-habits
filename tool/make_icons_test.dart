// Draws the app icons from the same painter the app uses.
// Run: flutter test tool/make_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulse/brand/logo.dart';
import 'package:pulse/brand/tokens.dart';

Future<List<int>> _icon(int px, {double mark = .78, bool rounded = false, bool transparent = false}) async {
  final rec = ui.PictureRecorder();
  final s = px.toDouble();
  final canvas = Canvas(rec);
  final rect = Offset.zero & Size(s, s);
  final bg = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF241A33), Palette.night],
    ).createShader(rect);
  if (transparent) {
    // Adaptive-icon foreground: the launcher supplies the background.
  } else if (rounded) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(s * .23)), bg);
  } else {
    canvas.drawRect(rect, bg);
  }
  final m = s * mark;
  final mr = Rect.fromCenter(center: rect.center + Offset(0, -s * .02), width: m, height: m);
  PulseMarkPainter.paintMark(canvas, mr);
  final img = await rec.endRecording().toImage(px, px);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  testWidgets('write icons', (tester) async {
    Txt.useGoogleFonts = false;
    await tester.runAsync(() async {
      Future<void> write(String path, int px, {double mark = .78, bool rounded = false, bool transparent = false}) async {
        File(path).writeAsBytesSync(await _icon(px, mark: mark, rounded: rounded, transparent: transparent));
      }

      await write('web/favicon.png', 64, mark: .86, rounded: true);
      await write('web/icons/Icon-192.png', 192, rounded: true);
      await write('web/icons/Icon-512.png', 512, rounded: true);
      await write('web/icons/Icon-maskable-192.png', 192, mark: .6);
      await write('web/icons/Icon-maskable-512.png', 512, mark: .6);
      const android = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
      for (final e in android.entries) {
        await write('android/app/src/main/res/mipmap-${e.key}/ic_launcher.png', e.value, rounded: true);
        // 108 dp canvas, mark inside the 66 dp safe zone.
        await write(
          'android/app/src/main/res/mipmap-${e.key}/ic_launcher_foreground.png',
          e.value * 108 ~/ 48,
          mark: .5,
          transparent: true,
        );
      }
      Directory('docs/brand').createSync(recursive: true);
      await write('docs/brand/icon-1024.png', 1024, rounded: true);
    });
  });
}
