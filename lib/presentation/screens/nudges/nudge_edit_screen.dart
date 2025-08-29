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

  // Category
  late String _category;

  // Schedule
  ScheduleKind _kind = ScheduleKind.timesPerDay;
  int _dailyTarget = 1;

  // Who selector
  String _selectedWho = 'Self';

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.template.title);
    _desc  = TextEditingController(text: widget.template.description);
    _category  = widget.template.category;

    // Pull template schedule if present
    final s = context.read<NudgesCubit>().state.schedules[widget.template.id];
    if (s != null) {
      _kind = s.kind;
      _dailyTarget = s.dailyTarget;
    } else if (widget.template.title.toLowerCase().contains('water')) {
      _kind = ScheduleKind.timesPerDay;
      _dailyTarget = 8;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _selectWho() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => const _WhoSelectorDialog(),
    );
    if (selected != null) {
      setState(() => _selectedWho = selected);
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
          icon: '✨', // Default icon since emoji picker removed
          schedule: schedule,
        );

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nudge added to $_selectedWho'),

        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NudgesCubit>().state;
    final categories = <String>{
      widget.template.category,
      ...state.allNudges.map((e) => e.category),
    }.toList()
      ..sort();

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
            _StyledFormField(
              label: 'Title',
              child: TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  hintText: 'e.g., Drink Water',
                  border: InputBorder.none,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            _StyledFormField(
              label: 'Description',
              child: TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Why/what to do',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category
            _StyledFormField(
              label: 'Category',
              child: DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
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
                _dailyTarget = t <= 0 ? 1 : t;
              }),
            ),
            const SizedBox(height: 16),

            // Who selector
            const Text(
              'Who',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: AppTheme.cardWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _selectWho,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _selectedWho == 'Self' ? Icons.person : 
                        _selectedWho.contains('School') || _selectedWho.contains('Work') ? Icons.group : 
                        Icons.person_outline,
                        color: AppTheme.textDark,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedWho,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      const Icon(Icons.expand_more, color: AppTheme.textGray),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32), // Extra padding before button

            // Save button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text('Add Nudge to $_selectedWho'),
              ),
            ),
            const SizedBox(height: 20), // Bottom padding to prevent cutoff
          ],
        ),
      ),
    );
  }
}

class _StyledFormField extends StatelessWidget {
  final String label;
  final Widget child;
  const _StyledFormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: AppTheme.cardWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: child,
          ),
        ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Type:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<ScheduleKind>(
                    isExpanded: true,
                    value: kind,
                    underline: Container(),
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
            const SizedBox(height: 16),
            if (kind != ScheduleKind.continuous)
              Row(
                children: [
                  const Text(
                    'Target today:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      initialValue: dailyTarget.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.borderGray),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _WhoSelectorDialog extends StatefulWidget {
  const _WhoSelectorDialog();

  @override
  State<_WhoSelectorDialog> createState() => _WhoSelectorDialogState();
}

class _WhoSelectorDialogState extends State<_WhoSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _allOptions = [
    {'name': 'Self', 'type': 'individual', 'icon': Icons.person},
    {'name': 'John', 'type': 'friend', 'icon': Icons.person_outline},
    {'name': 'Oliver', 'type': 'friend', 'icon': Icons.person_outline},
    {'name': 'School', 'type': 'group', 'icon': Icons.school},
    {'name': 'Work', 'type': 'group', 'icon': Icons.work},
  ];
  
  late List<Map<String, dynamic>> _filteredOptions;

  @override
  void initState() {
    super.initState();
    _filteredOptions = _allOptions;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterOptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = _allOptions;
      } else {
        _filteredOptions = _allOptions
            .where((option) =>
                option['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 320,
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Who is this nudge for?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _filterOptions,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.borderGray),
                ),
                filled: true,
                fillColor: AppTheme.backgroundGray,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredOptions.length,
                itemBuilder: (context, index) {
                  final option = _filteredOptions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        option['icon'],
                        color: AppTheme.primaryPurple,
                      ),
                      title: Text(option['name']),
                      subtitle: Text(
                        option['type'] == 'individual' ? 'Individual' :
                        option['type'] == 'friend' ? 'Friend' : 'Group',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGray,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(option['name']),
                    ),
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
