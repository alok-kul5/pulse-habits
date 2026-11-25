import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulse/app.dart';
import 'package:pulse/brand/tokens.dart';
import 'package:pulse/data/days.dart';
import 'package:pulse/screens/habit_detail.dart';
import 'package:pulse/screens/shell.dart';
import 'package:pulse/state/tracker.dart';
import 'package:pulse/widgets/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

final today = Days.of(DateTime(2026, 11, 25));
SemanticsHandle? _semantics;

Future<Tracker> boot(WidgetTester tester, {bool splash = false, bool seed = true}) async {
  // Run as the web demo would: no Health Connect, widget or reminders.
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  Txt.useGoogleFonts = false;
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  _semantics = tester.ensureSemantics();
  SharedPreferences.setMockInitialValues({});
  final t = Tracker(prefs: await SharedPreferences.getInstance(), clock: () => today, seed: seed);
  introDone.value = !splash;
  Shell.tab.value = 0;
  await tester.pumpWidget(PulseApp(tracker: t, showSplash: splash));
  await frames(tester, 2000);
  return t;
}

/// Lets entrance animations and their timers finish before the test ends.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  debugDefaultTargetPlatformOverride = null;
  _semantics?.dispose();
  _semantics = null;
}

/// Scrolls [semantics] into view, then taps it.
Future<void> press(WidgetTester tester, String semantics) async {
  final f = find.bySemanticsLabel(RegExp('^${RegExp.escape(semantics)}'));
  await tester.ensureVisible(f.first);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(f.hitTestable().first);
}

Finder tap(String semantics) => find.bySemanticsLabel(RegExp('^${RegExp.escape(semantics)}')).hitTestable();

void main() {
  testWidgets('the splash plays, then hands over to Today', (tester) async {
    await boot(tester, splash: true);
    expect(find.text('p'), findsWidgets); // the wordmark, letter by letter
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Today'), findsWidgets);
    expect(introDone.value, isTrue);
    expect(find.text('p'), findsNothing);
    await settle(tester);
  });

  testWidgets('ticking a habit counts it, and the last one is a perfect day', (tester) async {
    final t = await boot(tester);
    final open = t.dueToday.where((h) => !t.isDone(h.id, today)).toList();
    expect(open, isNotEmpty);

    await tester.tap(tap('Tick off ${open.first.name}'));
    await tester.pump(const Duration(milliseconds: 900));
    expect(t.isDone(open.first.id, today), isTrue);
    expect(find.text('${t.doneToday}'), findsWidgets);

    for (final h in open.skip(1)) {
      await tester.ensureVisible(find.bySemanticsLabel('Tick off ${h.name}'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(tap('Tick off ${h.name}'));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(t.doneToday, t.dueToday.length);
    expect(find.text('Perfect day'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('untick undoes it', (tester) async {
    final t = await boot(tester);
    final h = t.dueToday.firstWhere((h) => t.isDone(h.id, today));
    await tester.tap(tap('${h.name}, done. Tap to undo'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(t.isDone(h.id, today), isFalse);
    await settle(tester);
  });

  testWidgets('add a habit from the sheet', (tester) async {
    final t = await boot(tester, seed: false);
    expect(find.text('A clean slate'), findsOneWidget);
    await tester.tap(tap('New habit').first);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(find.byType(TextField), 'Practise guitar');
    await tester.pump();
    await press(tester, 'music');
    await tester.pump(const Duration(milliseconds: 300));
    await press(tester, 'Add habit');
    await tester.pump(const Duration(milliseconds: 800));
    expect(t.habits.single.name, 'Practise guitar');
    expect(t.habits.single.icon, 'music');
    expect(find.text('Practise guitar'), findsWidgets);
    await settle(tester);
  });

  testWidgets('an empty name cannot be saved', (tester) async {
    final t = await boot(tester, seed: false);
    await tester.tap(tap('New habit').first);
    await tester.pump(const Duration(milliseconds: 600));
    await press(tester, 'Add habit');
    await tester.pump(const Duration(milliseconds: 300));
    expect(t.habits, isEmpty);
    await settle(tester);
  });

  testWidgets('open a habit, then delete it and undo', (tester) async {
    final t = await boot(tester);
    final h = t.habits.first;
    await tester.tap(tap('Open ${h.name}'));
    await frames(tester, 1200);
    expect(find.byType(HabitDetail), findsOneWidget);
    expect(find.text('Last 26 weeks'.toUpperCase()), findsOneWidget);
    expect(find.text('STREAK'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pump(const Duration(milliseconds: 700));
    expect(t.habit(h.id), isNull);
    await frames(tester, 600);
    await tester.tap(find.text('Undo').hitTestable().last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(t.habit(h.id), isNotNull);
    await settle(tester);
  });

  testWidgets('log a workout and the week moves on', (tester) async {
    final t = await boot(tester);
    Shell.tab.value = 2;
    await frames(tester, 1200);
    final before = t.sessionsThisWeek;
    final count = t.workouts.length;
    await press(tester, 'Log workout');
    await tester.pump(const Duration(milliseconds: 700));
    await press(tester, 'Run');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(tap('More Kilometres'));
    await tester.pump();
    await press(tester, 'Save workout');
    await tester.pump(const Duration(milliseconds: 900));
    expect(t.workouts.length, count + 1);
    expect(t.sessionsThisWeek, before + 1);
    expect(t.recentWorkouts.first.km, 5.5);
    await settle(tester);
  });

  testWidgets('stats switch range and show the heatmap', (tester) async {
    await boot(tester);
    Shell.tab.value = 1;
    await frames(tester, 1200);
    expect(find.text('CONSISTENCY'), findsOneWidget);
    expect(find.text('week by week'), findsOneWidget);
    await tester.tap(find.text('4W'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('day by day'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('the web demo says plainly what is phone-only', (tester) async {
    final t = await boot(tester);
    Shell.tab.value = 3;
    await frames(tester, 1200);
    expect(find.text('This is sample data'), findsOneWidget);
    expect(find.text('PHONE ONLY'), findsWidgets);
    expect(find.text('Android only. The web demo uses sample steps.'), findsOneWidget);

    await press(tester, 'Start fresh');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(t.habits, isEmpty);
    expect(find.text('Your own data'), findsOneWidget);
    await settle(tester);
  });
}

/// Pumps real frames for [ms], so delayed entrances start and run.
Future<void> frames(WidgetTester tester, int ms) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
