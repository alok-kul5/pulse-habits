import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../brand/icons.dart';
import '../brand/tokens.dart';
import '../data/days.dart';
import '../data/models.dart';
import '../platform/phone.dart';
import '../platform/reminders.dart';
import '../state/tracker.dart';
import '../widgets/habit_card.dart';
import '../widgets/ui.dart';

/// New habit, or edit one. A live tile at the top takes on the colour and
/// icon as you pick them.
class HabitSheet extends StatefulWidget {
  const HabitSheet({super.key, this.habit});

  final Habit? habit;

  @override
  State<HabitSheet> createState() => _HabitSheetState();
}

class _HabitSheetState extends State<HabitSheet> {
  late final _name = TextEditingController(text: widget.habit?.name ?? '');
  late String _icon = widget.habit?.icon ?? 'bolt';
  late int _hue = widget.habit?.hue ?? 0;
  late Set<int> _days = {
    ...widget.habit?.weekdays ?? {1, 2, 3, 4, 5, 6, 7},
  };
  late int? _reminder = widget.habit?.reminder;

  bool get _valid => _name.text.trim().isNotEmpty && _days.isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = _reminder ?? 8 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now ~/ 60, minute: now % 60),
      builder: (context, child) => Theme(
        data: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: const ColorScheme.dark(primary: Palette.ember, surface: Palette.card, onSurface: Palette.ink),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _reminder = picked.hour * 60 + picked.minute);
  }

  Future<void> _save() async {
    if (!_valid) return;
    final t = TrackerScope.read(context);
    final phone = PhoneScope.of(context);
    final h = widget.habit;
    if (h == null) {
      t.addHabit(name: _name.text, icon: _icon, hue: _hue, weekdays: _days, reminder: _reminder);
    } else {
      h
        ..name = _name.text.trim()
        ..icon = _icon
        ..hue = _hue
        ..weekdays = _days
        ..reminder = _reminder;
      t.updateHabit(h);
    }
    if (_reminder != null && Reminders.platformSupported) await phone.reminders.requestPermission();
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final preview = Habit(id: 'preview', name: _name.text, icon: _icon, hue: _hue, createdDay: 0, weekdays: _days);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey('$_icon$_hue'),
                tween: Tween(begin: .7, end: 1),
                duration: Motion.of(context, Motion.slow),
                curve: Motion.spring,
                builder: (context, s, child) => Transform.scale(scale: s, child: child),
                child: HabitTile(habit: preview, size: 58, hero: false),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(widget.habit == null ? 'New habit' : 'Edit habit', style: Txt.display(30))),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            autofocus: widget.habit == null,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 40,
            onChanged: (_) => setState(() {}),
            style: Txt.text(18, weight: FontWeight.w700),
            cursorColor: Palette.ember,
            decoration: InputDecoration(
              hintText: 'Read 10 pages, walk after lunch…',
              hintStyle: Txt.text(16, color: Palette.ink3),
              counterText: '',
              filled: true,
              fillColor: Palette.raised,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Palette.ember, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Eyebrow('Colour'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < Palette.hues.length; i++)
                Pressable(
                  onTap: () => setState(() => _hue = i),
                  semantics: 'Colour ${i + 1}',
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.base),
                    curve: Motion.spring,
                    width: i == _hue ? 36 : 30,
                    height: i == _hue ? 36 : 30,
                    decoration: BoxDecoration(
                      color: Palette.hues[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: i == _hue ? Colors.white : Colors.transparent, width: 3),
                      boxShadow: i == _hue ? Palette.glow(Palette.hues[i], .6, 14) : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Eyebrow('Icon'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in HabitIcons.all.entries)
                Pressable(
                  onTap: () => setState(() => _icon = e.key),
                  semantics: e.key,
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.base),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: e.key == _icon ? Palette.hue(_hue) : Palette.raised,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(e.value, color: e.key == _icon ? Palette.night : Palette.ink2, size: 22),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Eyebrow(
            'Days',
            trailing: GestureDetector(
              onTap: () => setState(() => _days = {1, 2, 3, 4, 5, 6, 7}),
              child: Text('EVERY DAY', style: Txt.label(10.5, color: Palette.ember)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var d = 1; d <= 7; d++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Pressable(
                      semantics: Days.weekdayShort[d - 1],
                      onTap: () => setState(() {
                        if (!_days.remove(d)) _days.add(d);
                      }),
                      child: AnimatedContainer(
                        duration: Motion.of(context, Motion.base),
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: _days.contains(d) ? Palette.brand : null,
                          color: _days.contains(d) ? null : Palette.raised,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          Days.weekdayLetter[d - 1],
                          style: Txt.text(
                            14,
                            weight: FontWeight.w800,
                            color: _days.contains(d) ? Colors.white : Palette.ink3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Eyebrow('Reminder', trailing: Reminders.platformSupported ? null : const PhoneOnlyTag()),
          const SizedBox(height: 10),
          PanelCard(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            color: Palette.raised,
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Palette.gold, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _reminder == null ? null : _pickTime,
                    child: Text(
                      _reminder == null
                          ? 'No reminder'
                          : 'Every ${_days.length == 7 ? 'day' : 'due day'} at ${clock(_reminder!)}',
                      style: Txt.text(14.5, weight: FontWeight.w700),
                    ),
                  ),
                ),
                Switch(
                  value: _reminder != null,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Palette.ember,
                  onChanged: (v) {
                    if (v) {
                      _pickTime();
                    } else {
                      setState(() => _reminder = null);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          GlowButton(
            label: widget.habit == null ? 'Add habit' : 'Save',
            icon: Icons.check_rounded,
            onTap: _valid ? _save : null,
          ),
        ],
      ),
    );
  }
}
