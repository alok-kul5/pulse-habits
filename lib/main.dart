import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'brand/tokens.dart';
import 'state/tracker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Ask for every face the app uses up front, so the splash never
  // flashes a fallback font. Offline, give up quickly and carry on.
  for (final w in [FontWeight.w800]) {
    Txt.display(10, weight: w);
  }
  for (final w in [FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800]) {
    Txt.text(10, weight: w);
  }
  await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 3), onTimeout: () => []).catchError((_) => <void>[]);

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    // Storage unavailable (private mode and the like): run without saving.
  }
  runApp(PulseApp(tracker: Tracker(prefs: prefs)));
}
