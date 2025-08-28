import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../chat/chat_screen.dart';
import 'premade_nudges_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../business_logic/cubits/nudges_cubit.dart';
import '../../../business_logic/states/nudges_state.dart';
import '../../../data/models/nudge_model.dart';

enum _AddChoice { premade, custom }


class MyNudgesScreen extends StatefulWidget {
  const MyNudgesScreen({super.key});

  @override
  State<MyNudgesScreen> createState() => _MyNudgesScreenState();
}

class _MyNudgesScreenState extends State<MyNudgesScreen> {
  // Search & filters
  final TextEditingController _search = TextEditingController();
  _TypeFilter _typeFilter = _TypeFilter.all;
  String _categoryFilter = 'All';

  bool _actionableOnly = false; // new: show only scheduled/actionable

Future<void> _openFiltersDialog(BuildContext context) async {
  final cubitState = context.read<NudgesCubit>().state;
  final categories = <String>{'All', ...cubitState.myNudges.map((e) => e.category)}.toList()
    ..sort();

  // Local working copies (so Cancel does nothing)
  var type = _typeFilter;
  var category = _categoryFilter;
  var actionableOnly = _actionableOnly;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Filters'),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        content: StatefulBuilder(
          builder: (ctx, setLocal) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Type', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<_TypeFilter>(
                    value: _TypeFilter.all,
                    groupValue: type,
                    onChanged: (v) => setLocal(() => type = v ?? _TypeFilter.all),
                    title: const Text('All'),
                    dense: true,
                  ),
                  RadioListTile<_TypeFilter>(
                    value: _TypeFilter.premade,
                    groupValue: type,
                    onChanged: (v) => setLocal(() => type = v ?? _TypeFilter.premade),
                    title: const Text('Premade'),
                    dense: true,
                  ),
                  RadioListTile<_TypeFilter>(
                    value: _TypeFilter.custom,
                    groupValue: type,
                    onChanged: (v) => setLocal(() => type = v ?? _TypeFilter.custom),
                    title: const Text('Custom'),
                    dense: true,
                  ),
                  const SizedBox(height: 12),

                  // Category
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: categories.contains(category) ? category : 'All',
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setLocal(() => category = v ?? 'All'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Actionable only
                  SwitchListTile(
                    value: actionableOnly,
                    onChanged: (v) => setLocal(() => actionableOnly = v),
                    title: const Text('Show only scheduled/actionable'),
                    subtitle: const Text('Hide continuous, all-day habits'),
                    dense: true,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Reset to defaults
              setState(() {
                _typeFilter = _TypeFilter.all;
                _categoryFilter = 'All';
                _actionableOnly = false;
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _typeFilter = type;
                _categoryFilter = category;
                _actionableOnly = actionableOnly;
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      );
    },
  );
}


  // Selection mode
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _isCustom(String id) {
    // Our custom nudges are created via addCustomFromTemplate() with id 'nudge_<timestamp>_...'
    return id.startsWith('nudge_');
  }

List<Nudge> _applyFilters(NudgesState state) {
  final q = _search.text.trim().toLowerCase();
  final my = state.myNudges;

  final categories = my.map((n) => n.category).toSet();
  if (!categories.contains(_categoryFilter) && _categoryFilter != 'All') {
    _categoryFilter = 'All'; // safety reset if categories changed
  }

  bool isActionableId(String id) {
    // Prefer the state's helper if you added it; fallback checks schedule kind
    final s = state.schedules[id];
    if (s == null) return false;
    return s.kind != ScheduleKind.continuous;
  }

  return my.where((n) {
    // Type filter
    if (_typeFilter == _TypeFilter.custom && !_isCustom(n.id)) return false;
    if (_typeFilter == _TypeFilter.premade && _isCustom(n.id)) return false;

    // Category
    if (_categoryFilter != 'All' && n.category != _categoryFilter) return false;

    // Actionable only
    if (_actionableOnly && !isActionableId(n.id)) return false;

    // Search
    if (q.isNotEmpty) {
      final hay = '${n.title} ${n.description} ${n.category}'.toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }).toList()
    ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
}

  void _toggleSelectAll(List<Nudge> items) {
    setState(() {
      if (_selectedIds.length == items.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(items.map((e) => e.id));
      }
    });
  }

  Future<void> _confirmAndDelete(BuildContext context, List<String> ids) async {
    if (ids.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete nudges?'),
        content: Text(
          ids.length == 1
              ? 'Are you sure you want to delete this nudge? This cannot be undone.'
              : 'Are you sure you want to delete ${ids.length} nudges? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final cubit = context.read<NudgesCubit>();
      for (final id in ids) {
        cubit.removeFromMyNudges(id);
      }
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ids.length == 1 ? 'Nudge deleted' : '${ids.length} nudges deleted'),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openModifySheet(
    BuildContext context,
    NudgesState state,
    Nudge n,
  ) async {
    final schedule = state.schedules[n.id];
    final kindInitial = schedule?.kind ?? ScheduleKind.timesPerDay;
    final targetInitial = schedule?.dailyTarget ?? 1;
    final todayCount = state.dailyCountFor(n.id, DateTime.now());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: _ModifySheet(
            nudge: n,
            initialKind: kindInitial,
            initialTarget: targetInitial,
            initialCount: todayCount,
            onSave: (newKind, newTarget, newCount) async {
              final cubit = context.read<NudgesCubit>();
              // 1) Update schedule
              cubit.setSchedule(
                n.id,
                NudgeScheduleSimple(kind: newKind, dailyTarget: newTarget),
              );

              // 2) Update today's logged count using log/undo diff
              final currentCount = state.dailyCountFor(n.id, DateTime.now());
              final diff = newCount - currentCount;
              if (diff > 0) {
                for (int i = 0; i < diff; i++) {
                  cubit.logNow(n.id);
                }
              } else if (diff < 0) {
                for (int i = 0; i < -diff; i++) {
                  cubit.undoLog(n.id);
                }
              }

              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: _selectionMode
            ? Text('${_selectedIds.length} selected')
            : const Text('My Nudges', style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectionMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        actions: [
  if (_selectionMode) ...[
    IconButton(
      tooltip: 'Select all',
      icon: const Icon(Icons.select_all),
      onPressed: () {
        final state = context.read<NudgesCubit>().state;
        final items = _applyFilters(state);
        _toggleSelectAll(items);
      },
    ),
    IconButton(
      tooltip: 'Delete selected',
      icon: const Icon(Icons.delete_outline),
      onPressed: () => _confirmAndDelete(context, _selectedIds.toList()),
    ),
  ] else
    PopupMenuButton<_AddChoice>(
      tooltip: 'Add nudge',
      icon: const Icon(Icons.add),
      onSelected: (choice) {
        switch (choice) {
          case _AddChoice.premade:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremadeNudgesScreen()),
            );
            break;
          case _AddChoice.custom:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            );
            break;
        }
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem(
          value: _AddChoice.custom,
          child: ListTile(
            leading: Icon(Icons.auto_awesome),
            title: Text('Createa custom nudge (AI Coach)'),
          ),
        ),
      
        PopupMenuItem(
          value: _AddChoice.premade,
          child: ListTile(
            leading: Icon(Icons.lightbulb_outline),
            title: Text('Browse premade nudges'),
          ),
        ),
        ],
    ),
],
),
      body: BlocBuilder<NudgesCubit, NudgesState>(
        builder: (context, state) {
          final filtered = _applyFilters(state);
          final categories = <String>{'All', ...state.myNudges.map((e) => e.category)};

          return Column(
            children: [
              // Search + filters
              Container(
                color: AppTheme.cardWhite,
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingLarge,
                  12,
                  AppConstants.paddingLarge,
                  12,
                ),
                child: Column(
                  children: [
                    // Search field
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search my nudges...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppTheme.backgroundGray,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Type filter chips + Category dropdown + Select mode toggle
// ⬇️ Replace your old Row of chips with this block
Row(
  children: [
    // Left: Filters button
    TextButton.icon(
      onPressed: () => _openFiltersDialog(context),
      icon: const Icon(Icons.filter_list),
      label: const Text('Filters'),
    ),
    const Spacer(),
    // Right: Select / Select all (text buttons)
    if (_selectionMode)
      TextButton(
        onPressed: () {
          final state = context.read<NudgesCubit>().state;
          final items = _applyFilters(state);
          _toggleSelectAll(items);
        },
        child: const Text('Select all'),
      )
    else
      TextButton(
        onPressed: () {
          setState(() {
            _selectionMode = true;
            _selectedIds.clear();
          });
        },
        child: const Text('Select'),
      ),
  ],
),
],
                ),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final n = filtered[index];
                          final isSelected = _selectedIds.contains(n.id);
                          final schedule = state.schedules[n.id];
                          final target = schedule?.dailyTarget ?? 1;
                          final kind = schedule?.kind ?? ScheduleKind.timesPerDay;
                          final countToday = state.dailyCountFor(n.id, DateTime.now());

                          final card = _NudgeRowCard(
                            nudge: n,
                            isSelected: isSelected,
                            selectionMode: _selectionMode,
                            countToday: countToday,
                            target: target,
                            scheduleKind: kind,
                            isCustom: _isCustom(n.id),
                            onTap: () {
                              if (_selectionMode) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedIds.remove(n.id);
                                  } else {
                                    _selectedIds.add(n.id);
                                  }
                                });
                              } else {
                                _openModifySheet(context, state, n);
                              }
                            },
                            onModify: () => _openModifySheet(context, state, n),
                            onSelectionChanged: (val) {
                              setState(() {
                                if (val) {
                                  _selectedIds.add(n.id);
                                } else {
                                  _selectedIds.remove(n.id);
                                }
                              });
                            },
                          );

                          // Slide to delete (with confirm)
                          return Dismissible(
                            key: ValueKey('dismiss_${n.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete, color: Colors.red),
                            ),
                            confirmDismiss: (_) async {
                              await _confirmAndDelete(context, [n.id]);
                              return false; // we handle deletion ourselves
                            },
                            child: card,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _TypeFilter { all, premade, custom }


class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textGray.withOpacity(0.6)),
            const SizedBox(height: 12),
            const Text(
              'No nudges match your filters',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try clearing search or changing filters.',
              style: TextStyle(color: AppTheme.textGray),
            ),
          ],
        ),
      ),
    );
  }
}

class _NudgeRowCard extends StatelessWidget {
  final Nudge nudge;
  final bool selectionMode;
  final bool isSelected;
  final int countToday;
  final int target;
  final ScheduleKind scheduleKind;
  final bool isCustom;
  final VoidCallback onModify;
  final VoidCallback onTap;
  final ValueChanged<bool> onSelectionChanged;

  const _NudgeRowCard({
    required this.nudge,
    required this.selectionMode,
    required this.isSelected,
    required this.countToday,
    required this.target,
    required this.scheduleKind,
    required this.isCustom,
    required this.onModify,
    required this.onTap,
    required this.onSelectionChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (target == 0) ? 0.0 : (countToday / target).clamp(0.0, 1.0);

    return Material(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderGray),
          ),
          child: Row(
            children: [
              // Progress ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 6,
                      backgroundColor: AppTheme.backgroundGray,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                    ),
                  ),
                  const Icon(Icons.checklist_rtl, color: AppTheme.primaryPurple),
                ],
              ),
              const SizedBox(width: 12),

              // Title + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            nudge.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Custom',
                              style: TextStyle(fontSize: 11, color: AppTheme.primaryPurple),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundGray,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Premade',
                              style: TextStyle(fontSize: 11, color: AppTheme.textGray),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nudge.category,
                      style: const TextStyle(color: AppTheme.textGray),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$countToday / $target today • ${_hint(scheduleKind)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right side: selection or modify
              if (selectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (v) => onSelectionChanged(v ?? false),
                )
              else
                OutlinedButton.icon(
                  onPressed: onModify,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Modify'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(96, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _hint(ScheduleKind k) {
    switch (k) {
      case ScheduleKind.hourly:
        return 'hourly';
      case ScheduleKind.timesPerDay:
        return 'x/day';
      case ScheduleKind.specificTimes:
        return 'at times';
      case ScheduleKind.continuous:
        return 'continuous';
    }
  }
}

class _ModifySheet extends StatefulWidget {
  final Nudge nudge;
  final ScheduleKind initialKind;
  final int initialTarget;
  final int initialCount;
  final Future<void> Function(ScheduleKind, int, int) onSave;

  const _ModifySheet({
    required this.nudge,
    required this.initialKind,
    required this.initialTarget,
    required this.initialCount,
    required this.onSave,
  });

  @override
  State<_ModifySheet> createState() => _ModifySheetState();
}

class _ModifySheetState extends State<_ModifySheet> {
  late ScheduleKind _kind;
  late int _target;
  late int _count;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _target = widget.initialTarget <= 0 ? 1 : widget.initialTarget;
    _count = widget.initialCount.clamp(0, 999);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            height: 4,
            width: 44,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.borderGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Modify "${widget.nudge.title}"',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 16),

          // Today count editor
          _LabeledRow(
            label: 'Logged today',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _count > 0 ? () => setState(() => _count -= 1) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    '$_count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _count < 999 ? () => setState(() => _count += 1) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Schedule kind + target
          _LabeledRow(
            label: 'Type',
            child: DropdownButton<ScheduleKind>(
              value: _kind,
              items: const [
                DropdownMenuItem(value: ScheduleKind.hourly, child: Text('Hourly')),
                DropdownMenuItem(value: ScheduleKind.timesPerDay, child: Text('Times per day')),
                DropdownMenuItem(value: ScheduleKind.specificTimes, child: Text('Specific times')),
                DropdownMenuItem(value: ScheduleKind.continuous, child: Text('Continuous')),
              ],
              onChanged: (k) {
                if (k == null) return;
                setState(() {
                  _kind = k;
                  if (_kind == ScheduleKind.continuous && _target != 1) _target = 1;
                });
              },
            ),
          ),
          const SizedBox(height: 8),

          if (_kind != ScheduleKind.continuous)
            _LabeledRow(
              label: 'Target today',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _target > 1 ? () => setState(() => _target -= 1) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '$_target',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _target < 999 ? () => setState(() => _target += 1) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Continuous habits won’t appear on Home; they’ll be tracked in Analytics.',
                  style: TextStyle(color: AppTheme.textGray),
                ),
              ),
            ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      await widget.onSave(_kind, _target, _count);
                      if (mounted) setState(() => _busy = false);
                    },
              icon: _busy
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: child),
        ],
      ),
    );
  }
}
