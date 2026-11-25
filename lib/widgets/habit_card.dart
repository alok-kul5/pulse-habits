import 'package:material_ui/material_ui.dart';

import '../brand/icons.dart';
import '../brand/tokens.dart';
import '../data/models.dart';
import 'check.dart';
import 'ui.dart';

/// The habit's coloured icon tile. Flies between the list and the detail page.
class HabitTile extends StatelessWidget {
  const HabitTile({super.key, required this.habit, this.size = 50, this.hero = true});

  final Habit habit;
  final double size;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final c = Palette.hue(habit.hue);
    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(c, Colors.white, .12)!, Color.lerp(c, Palette.night, .25)!],
        ),
        boxShadow: Palette.glow(c, .35, size * .4),
      ),
      child: Icon(HabitIcons.of(habit.icon), color: Palette.night, size: size * .5),
    );
    return hero ? Hero(tag: 'habit-${habit.id}', child: tile) : tile;
  }
}

class HabitCard extends StatefulWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.done,
    required this.streak,
    required this.onToggle,
    required this.onOpen,
    this.dim = false,
  });

  final Habit habit;
  final bool done;
  final int streak;

  /// Called with the check button's centre on screen, for effects that start there.
  final void Function(Offset orb) onToggle;
  final VoidCallback onOpen;
  final bool dim;

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  final _orb = GlobalKey();

  void _toggle() {
    final box = _orb.currentContext?.findRenderObject() as RenderBox?;
    widget.onToggle(box == null ? Offset.zero : box.localToGlobal(box.size.center(Offset.zero)));
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    final c = Palette.hue(h.hue);
    return Opacity(
      opacity: widget.dim ? .55 : 1,
      child: Pressable(
        onTap: widget.onOpen,
        scale: .975,
        haptic: false,
        semantics: 'Open ${h.name}',
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.slow),
          curve: Motion.out,
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Palette.card,
            gradient: widget.done
                ? LinearGradient(colors: [c.withValues(alpha: .2), Palette.card], stops: const [0, .75])
                : null,
            border: Border.all(color: widget.done ? c.withValues(alpha: .45) : Palette.line.withValues(alpha: .8)),
          ),
          child: Row(
            children: [
              HabitTile(habit: h),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Txt.text(16, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 15,
                          color: widget.streak > 0 ? Palette.gold : Palette.ink3,
                        ),
                        const SizedBox(width: 3),
                        RollingNumber(
                          widget.streak,
                          style: Txt.text(
                            13,
                            weight: FontWeight.w800,
                            color: widget.streak > 0 ? Palette.gold : Palette.ink3,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '  ·  ${h.scheduleLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Txt.text(13, weight: FontWeight.w600, color: Palette.ink3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CheckOrb(
                key: _orb,
                done: widget.done,
                color: c,
                onTap: _toggle,
                label: widget.done ? '${h.name}, done. Tap to undo' : 'Tick off ${h.name}',
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
