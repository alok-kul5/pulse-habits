import 'dart:math' as math;

import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';
import '../platform/widget_sync.dart';
import '../state/tracker.dart';

/// A faithful copy of the Android home-screen widget, drawn from the same
/// snapshot the native widget reads. Shown in the app (and on the web,
/// where the real widget can't exist).
class WidgetPreview extends StatelessWidget {
  const WidgetPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TrackerScope.of(context);
    final s = WidgetSync.snapshot(t);
    final habits = (jsonDecode(s['habits'] as String) as List).cast<Map<String, dynamic>>();
    final heat = s['heat'] as String;
    return AspectRatio(
      aspectRatio: 1.55,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF221A2E), Palette.night],
          ),
          border: Border.all(color: Palette.line),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 30, offset: const Offset(0, 14)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('PULSE', style: Txt.label(10, color: Palette.ember)),
                      const Spacer(),
                      const Icon(Icons.local_fire_department_rounded, size: 15, color: Palette.gold),
                      Text(
                        '${s['streak']}',
                        style: Txt.text(13, weight: FontWeight.w800, color: Palette.gold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${s['done']}/${s['due']} today', style: Txt.display(22)),
                  const SizedBox(height: 8),
                  for (final h in habits.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: h['done'] == true ? Color(h['color'] as int) : Colors.transparent,
                              border: Border.all(color: Color(h['color'] as int), width: 2),
                            ),
                            child: h['done'] == true
                                ? const Icon(Icons.check_rounded, size: 9, color: Palette.night)
                                : null,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              h['name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Txt.text(
                                11.5,
                                weight: FontWeight.w700,
                                color: h['done'] == true ? Palette.ink3 : Palette.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 8,
              child: LayoutBuilder(
                builder: (context, box) {
                  final cell = math.min((box.maxWidth - 6 * 3) / 7, (box.maxHeight - 6 * 3) / 7);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var d = 0; d < 7; d++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              for (var w = 0; w < 7; w++)
                                Container(
                                  width: cell,
                                  height: cell,
                                  margin: EdgeInsets.only(right: w == 6 ? 0 : 3),
                                  decoration: BoxDecoration(
                                    color: switch (heat[w * 7 + d]) {
                                      ' ' => Colors.transparent,
                                      '-' => Palette.heat(-1),
                                      final c => Palette.heat(int.parse(c)),
                                    },
                                    borderRadius: BorderRadius.circular(cell * .28),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
