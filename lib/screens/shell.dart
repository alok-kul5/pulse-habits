import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../brand/tokens.dart';
import 'stats.dart';
import 'today.dart';
import 'train.dart';
import 'you.dart';

/// The four tabs under a floating capsule. Tabs keep their state and
/// cross-fade with a small lift when you switch.
class Shell extends StatefulWidget {
  const Shell({super.key});

  static final tab = ValueNotifier<int>(0);

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  static const _tabs = [
    (Icons.radio_button_checked_rounded, 'Today'),
    (Icons.insights_rounded, 'Stats'),
    (Icons.fitness_center_rounded, 'Train'),
    (Icons.person_rounded, 'You'),
  ];

  final _visited = <int>{0};

  @override
  void initState() {
    super.initState();
    Shell.tab.addListener(_onTab);
  }

  @override
  void dispose() {
    Shell.tab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() => setState(() => _visited.add(Shell.tab.value));

  @override
  Widget build(BuildContext context) {
    final i = Shell.tab.value;
    final pages = const [TodayScreen(), StatsScreen(), TrainScreen(), YouScreen()];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(systemNavigationBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Palette.night,
        extendBody: true,
        body: Stack(
          children: [
            for (var k = 0; k < pages.length; k++)
              if (_visited.contains(k))
                IgnorePointer(
                  ignoring: k != i,
                  child: ExcludeSemantics(
                    excluding: k != i,
                    // The fade sits above TickerMode so it can still finish
                    // after the page underneath is muted.
                    child: AnimatedOpacity(
                      opacity: k == i ? 1 : 0,
                      duration: Motion.of(context, Motion.base),
                      curve: Motion.out,
                      child: AnimatedSlide(
                        offset: k == i ? Offset.zero : const Offset(0, .015),
                        duration: Motion.of(context, Motion.base),
                        curve: Motion.out,
                        child: TickerMode(enabled: k == i, child: pages[k]),
                      ),
                    ),
                  ),
                ),
          ],
        ),
        bottomNavigationBar: _TabBar(
          index: i,
          tabs: _tabs,
          onTap: (k) {
            if (k == i) return;
            HapticFeedback.selectionClick();
            Shell.tab.value = k;
          },
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.tabs, required this.onTap});

  final int index;
  final List<(IconData, String)> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 66,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Palette.card.withValues(alpha: .78),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Palette.line.withValues(alpha: .9)),
            ),
            child: Row(
              children: [
                for (var k = 0; k < tabs.length; k++)
                  Expanded(
                    flex: k == index ? 16 : 10,
                    child: _Tab(icon: tabs[k].$1, label: tabs[k].$2, active: k == index, onTap: () => onTap(k)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.slow),
          curve: Motion.spring,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            gradient: active ? Palette.brand : null,
            borderRadius: BorderRadius.circular(24),
            boxShadow: active ? Palette.glow(Palette.flare, .4, 18) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.08 : 1,
                duration: Motion.of(context, Motion.base),
                curve: Motion.spring,
                child: Icon(icon, size: 22, color: active ? Colors.white : Palette.ink3),
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: Motion.of(context, Motion.slow),
                  curve: Motion.out,
                  child: active
                      ? Padding(
                          padding: const EdgeInsets.only(left: 7),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: Txt.text(13.5, weight: FontWeight.w800, color: Colors.white),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
