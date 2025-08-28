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
  late TextEditingController _category;
  late TextEditingController _icon;

  ScheduleKind _kind = ScheduleKind.timesPerDay;
  int _dailyTarget = 1;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.template.title);
    _desc = TextEditingController(text: widget.template.description);
    _category = TextEditingController(text: widget.template.category);
    _icon = TextEditingController(text: widget.template.icon);
    // Try to preselect a sensible default if template has a schedule
    final state = context.read<NudgesCubit>().state;
    final tplSched = state.schedules[widget.template.id];
    if (tplSched != null) {
      _kind = tplSched.kind;
      _dailyTarget = tplSched.dailyTarget;
    } else {
      // heuristic: water → 8/day
      if (widget.template.title.toLowerCase().contains('water')) {
        _kind = ScheduleKind.timesPerDay;
        _dailyTarget = 8;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _category.dispose();
    _icon.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final schedule = NudgeScheduleSimple(kind: _kind, dailyTarget: _dailyTarget);

    context.read<NudgesCubit>().addCustomFromTemplate(
          widget.template,
          title: _title.text,
          description: _desc.text,
          category: _category.text,
          icon: _icon.text,
          schedule: schedule,
        );

    if (!mounted) return;
    Navigator.of(context).pop(true); // return success
  }

  @override
  Widget build(BuildContext context) {
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
            // Category + Icon (simple strings for now)
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Category',
                    child: TextFormField(
                      controller: _category,
                      decoration: const InputDecoration(
                        hintText: 'Health & Wellness',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledField(
                    label: 'Icon name',
                    child: TextFormField(
                      controller: _icon,
                      decoration: const InputDecoration(
                        hintText: 'water_drop',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                _dailyTarget = t;
              }),
            ),
            const SizedBox(height: 20),

            // Save
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _save,
                icon: _submitting
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
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
                DropdownButton<ScheduleKind>(
                  value: kind,
                  onChanged: (k) {
                    if (k == null) return;
                    // If switching to continuous, cap target at 1
                    final t = (k == ScheduleKind.continuous)
                        ? 1
                        : (dailyTarget <= 0 ? 1 : dailyTarget);
                    onChanged(k, t);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ScheduleKind.hourly,
                      child: Text('Hourly'),
                    ),
                    DropdownMenuItem(
                      value: ScheduleKind.timesPerDay,
                      child: Text('Times per day'),
                    ),
                    DropdownMenuItem(
                      value: ScheduleKind.specificTimes,
                      child: Text('Specific times'),
                    ),
                    DropdownMenuItem(
                      value: ScheduleKind.continuous,
                      child: Text('Continuous (not on Home page)'),
                    ),
                  ],
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
