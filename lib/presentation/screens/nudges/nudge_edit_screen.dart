import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/nudge_model.dart';
import '../../../business_logic/cubits/nudges_cubit.dart';
import '../../../business_logic/states/nudges_state.dart';

class NudgeEditScreen extends StatefulWidget {
  final Nudge template;
  const NudgeEditScreen({super.key, required this.template});

  @override
  State<NudgeEditScreen> createState() => _NudgeEditScreenState();
}

class _NudgeEditScreenState extends State<NudgeEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _title;
  late TextEditingController _desc;

  // Category (dropdown) and emoji icon
  late String _category;
  String _iconEmoji = '✨';

  // schedule
  ScheduleKind _kind = ScheduleKind.timesPerDay;
  int _dailyTarget = 1;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.template.title);
    _desc  = TextEditingController(text: widget.template.description);

    // default category/icon
    _category  = widget.template.category;
    _iconEmoji = _extractEmojiOrFallback(widget.template.icon);

    // pull template schedule if present
    final s = context.read<NudgesCubit>().state.schedules[widget.template.id];
    if (s != null) {
      _kind = s.kind;
      _dailyTarget = s.dailyTarget;
    } else if (widget.template.title.toLowerCase().contains('water')) {
      _kind = ScheduleKind.timesPerDay;
      _dailyTarget = 8;
    }
  }

  String _extractEmojiOrFallback(String icon) {
    // If template was using a Material icon name before, fall back to a default emoji.
    // If it already contains an emoji (length==1 or composed), keep it.
    final r = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
    return r.hasMatch(icon) ? icon : '✨';
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickEmoji() async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => const _EmojiPickerDialog(),
    );
    if (chosen != null && chosen.isNotEmpty) {
      setState(() => _iconEmoji = chosen);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final schedule = NudgeScheduleSimple(kind: _kind, dailyTarget: _dailyTarget);

    context.read<NudgesCubit>().addCustomFromTemplate(
          widget.template,
          title: _title.text,
          description: _desc.text,
          category: _category,
          icon: _iconEmoji, // store the emoji directly in Nudge.icon
          schedule: schedule,
        );

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nudge added to My Nudges'),
        duration: Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // categories from user’s current nudges + template category (safe default)
    final state = context.watch<NudgesCubit>().state;
    final categories = <String>{
      widget.template.category,
      ...state.allNudges.map((e) => e.category),
    }.toList()
      ..sort();

    // ensure current category exists
    if (!categories.contains(_category)) categories.insert(0, _category);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Customize Nudge'),
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            _LabeledField(
              label: 'Title',
              child: TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  hintText: 'e.g., Drink Water',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            _LabeledField(
              label: 'Description',
              child: TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Why/what to do',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
// ⬇️ REPLACE the Row(...) that wraps Category + Icon with this:
LayoutBuilder(
  builder: (context, constraints) {
    final isNarrow = constraints.maxWidth < 360; // tweak threshold if needed

    final categoryField = _LabeledField(
      label: 'Category',
      child: DropdownButtonFormField<String>(
        isExpanded: true, // ✅ let text shrink with ellipsis
        value: _category,
        items: categories
            .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (v) => setState(() => _category = v ?? _category),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          filled: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );

    final emojiField = _LabeledField(
      label: 'Icon (emoji)',
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _pickEmoji,
        child: Row(
          children: [
            Text(_iconEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Choose emoji', overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );

    if (isNarrow) {
      // Stack vertically on narrow screens – no overflow possible
      return Column(
        children: [
          categoryField,
          const SizedBox(height: 12),
          emojiField,
        ],
      );
    }

    // Wide enough: show side-by-side with flex
    return Row(
      children: [
        Expanded(flex: 7, child: categoryField),
        const SizedBox(width: 12),
        Expanded(flex: 5, child: emojiField),
      ],
    );
  },
),

            // Category (dropdown) + Emoji picker
            
            const SizedBox(height: 16),

            // Schedule
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            _SchedulePicker(
              kind: _kind,
              dailyTarget: _dailyTarget,
              onChanged: (k, t) => setState(() {
                _kind = k;
                _dailyTarget = t <= 0 ? 1 : t;
              }),
            ),
            const SizedBox(height: 20),

            // Save
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Add to My Nudges'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            )),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SchedulePicker extends StatelessWidget {
  final ScheduleKind kind;
  final int dailyTarget;
  final void Function(ScheduleKind, int) onChanged;

  const _SchedulePicker({
    required this.kind,
    required this.dailyTarget,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Kind
            Row(
              children: [
                const Text('Type:'),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<ScheduleKind>(
                    isExpanded: true, // ✅ avoid overflow here too
                    value: kind,
                    onChanged: (k) {
                      if (k == null) return;
                      final t = (k == ScheduleKind.continuous) ? 1 : (dailyTarget <= 0 ? 1 : dailyTarget);
                      onChanged(k, t);
                    },
                    items: const [
                      DropdownMenuItem(value: ScheduleKind.hourly, child: Text('Hourly')),
                      DropdownMenuItem(value: ScheduleKind.timesPerDay, child: Text('Times per day')),
                      DropdownMenuItem(value: ScheduleKind.specificTimes, child: Text('Specific times')),
                      DropdownMenuItem(value: ScheduleKind.continuous, child: Text('Continuous (not on Home)')),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Target
            if (kind != ScheduleKind.continuous)
              Row(
                children: [
                  const Text('Target today:'),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      initialValue: dailyTarget.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (v) {
                        final n = int.tryParse(v) ?? dailyTarget;
                        onChanged(kind, n.clamp(1, 100));
                      },
                    ),
                  ),
                ],
              )
            else
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'This will not appear on Home; tracked in Analytics.',
                  style: TextStyle(color: AppTheme.textGray),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmojiPickerDialog extends StatefulWidget {
  const _EmojiPickerDialog();

  @override
  State<_EmojiPickerDialog> createState() => _EmojiPickerDialogState();
}

class _EmojiPickerDialogState extends State<_EmojiPickerDialog> {
  final TextEditingController _q = TextEditingController();
  late List<_EmojiItem> _items;
  late List<_EmojiItem> _filtered;

  @override
  void initState() {
    super.initState();
    _items = _emojiCatalog;
    _filtered = _items;
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _items;
      } else {
        _filtered = _items.where((e) {
          if (e.name.contains(q)) return true;
          for (final k in e.keywords) {
            if (k.contains(q)) return true;
          }
          return false;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final grid = GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final it = _filtered[i];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).pop(it.emoji),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderGray),
            ),
            child: Center(child: Text(it.emoji, style: const TextStyle(fontSize: 22))),
          ),
        );
      },
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 380,
        height: 420,
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text('Pick an emoji', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _q,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: 'Search emoji… (e.g., water, run, sleep)',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: AppTheme.backgroundGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _q.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _q.clear();
                            _filter('');
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: grid),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _EmojiItem {
  final String emoji;
  final String name;
  final List<String> keywords;
  const _EmojiItem(this.emoji, this.name, this.keywords);
}

// Minimal catalog (extend as needed)
const List<_EmojiItem> _emojiCatalog = [
  _EmojiItem('💧', 'water', ['drink','hydrate','thirst','glass']),
  _EmojiItem('🥤', 'drink', ['water','hydrate','cup','beverage']),
  _EmojiItem('🚶‍♂️', 'walk', ['steps','exercise','move']),
  _EmojiItem('🏃‍♀️', 'run', ['jog','exercise','fitness']),
  _EmojiItem('🧘', 'meditate', ['calm','mindfulness','breathe']),
  _EmojiItem('🛏️', 'sleep', ['bedtime','rest','night']),
  _EmojiItem('🍎', 'fruit', ['health','eat','food']),
  _EmojiItem('🥦', 'veggies', ['health','eat','food']),
  _EmojiItem('📵', 'digital detox', ['phone','screen','limit']),
  _EmojiItem('📚', 'study', ['read','learn','focus']),
  _EmojiItem('🧹', 'clean', ['tidy','chores','house']),
  _EmojiItem('❤️', 'heart', ['love','relationship']),
  _EmojiItem('📞', 'call', ['phone','family','friend']),
  _EmojiItem('☀️', 'morning', ['sun','wake','day']),
  _EmojiItem('🌙', 'night', ['evening','sleep']),
  _EmojiItem('🔥', 'motivation', ['streak','goal']),
  _EmojiItem('🧠', 'focus', ['work','deep','productivity']),
  _EmojiItem('💤', 'nap', ['rest','sleep']),
  _EmojiItem('🧴', 'skincare', ['health','routine']),
  _EmojiItem('🧑‍🍳', 'cook', ['meal','food']),
  _EmojiItem('🧴', 'hydrate skin', ['moisturize','skincare']),
  _EmojiItem('📝', 'journal', ['write','reflect']),
  _EmojiItem('🎧', 'listen', ['podcast','music']),
  _EmojiItem('📖', 'read', ['book','study']),
  _EmojiItem('🕒', 'on time', ['schedule','punctual']),
  _EmojiItem('✨', 'sparkle', ['general','default']),
];
