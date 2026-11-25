import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:material_ui/material_ui.dart';

import 'brand/tokens.dart';
import 'platform/demo_link.dart';
import 'platform/health.dart';
import 'platform/phone.dart';
import 'platform/widget_sync.dart';
import 'screens/habit_detail.dart';
import 'screens/habit_sheet.dart';
import 'screens/health_explainer.dart';
import 'screens/routes.dart';
import 'screens/shell.dart';
import 'screens/splash.dart';
import 'screens/workout_sheet.dart';
import 'state/tracker.dart';
import 'widgets/ui.dart';

class PulseApp extends StatefulWidget {
  const PulseApp({super.key, required this.tracker, this.phone, this.showSplash = true, this.link = const DemoLink()});

  final Tracker tracker;
  final Phone? phone;
  final bool showSplash;
  final DemoLink link;

  @override
  State<PulseApp> createState() => _PulseAppState();
}

class _PulseAppState extends State<PulseApp> with WidgetsBindingObserver {
  late bool _splash = widget.showSplash && widget.link.splash;
  late final Phone _phone = widget.phone ?? Phone();
  final _nav = GlobalKey<NavigatorState>();
  Timer? _debounce;
  StreamSubscription<String>? _ticks;
  String _reminderKey = '';

  Tracker get _t => widget.tracker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _t.addListener(_onChange);
    _syncPhone();
    _ticks = WidgetSync.ticks().listen(_tickFromWidget);
    // No splash, no curtain: let screens play their entrance right away.
    if (!_splash) introDone.value = true;
    _boot();
    _follow(widget.link);
  }

  void _follow(DemoLink link) {
    if (link.tab != 0) Shell.tab.value = link.tab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = _nav.currentState;
      final ctx = _nav.currentContext;
      if (nav == null || ctx == null) return;
      if (link.habit != null && _t.habit(link.habit!) != null) {
        nav.push(heroRoute(HabitDetail(habitId: link.habit!)));
      } else if (link.sheet == 'new') {
        showPulseSheet(ctx, (_) => const HabitSheet());
      } else if (link.sheet == 'log') {
        showPulseSheet(ctx, (_) => const WorkoutSheet());
      }
    });
  }

  Future<void> _boot() async {
    await _refreshSteps();
    if (await _phone.health.openedForRationale()) {
      _nav.currentState?.push(riseRoute(const HealthExplainer()));
    }
  }

  Future<void> _refreshSteps() async {
    if (await _phone.refreshHealth() == HealthStatus.granted) {
      final steps = await _phone.health.steps(182);
      if (steps.values.any((v) => v > 0)) _t.setHealthSteps(steps);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSteps();
      _syncPhone();
    }
  }

  void _tickFromWidget(String id) {
    if (_t.habit(id) == null) return;
    Shell.tab.value = 0;
    _nav.currentState?.popUntil((r) => r.isFirst);
    // Let Today appear first, so the check-off plays on screen.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!_t.isDone(id, _t.today)) _t.toggle(id);
    });
  }

  void _onChange() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _syncPhone);
  }

  void _syncPhone() {
    WidgetSync.push(_t);
    final key = _t.habits.map((h) => '${h.id}:${h.name}:${h.reminder}').join('|');
    if (key != _reminderKey) {
      _reminderKey = key;
      _phone.reminders.sync(_t.habits);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _t.removeListener(_onChange);
    _debounce?.cancel();
    _ticks?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PhoneScope(
      phone: _phone,
      child: TrackerScope(
        tracker: _t,
        child: MaterialApp(
          title: 'Pulse',
          navigatorKey: _nav,
          debugShowCheckedModeBanner: false,
          // Let mouse and trackpad drag lists too (the web demo).
          scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: PointerDeviceKind.values.toSet()),
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Palette.night,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Palette.ember,
              brightness: Brightness.dark,
              surface: Palette.night,
            ),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: Palette.ember,
              selectionColor: Palette.ember.withValues(alpha: .3),
              selectionHandleColor: Palette.ember,
            ),
          ),
          builder: (context, child) => Stack(
            children: [
              child!,
              if (_splash)
                Positioned.fill(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Splash(onDone: () => setState(() => _splash = false)),
                  ),
                ),
            ],
          ),
          home: const Shell(),
        ),
      ),
    );
  }
}
