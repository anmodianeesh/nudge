import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

import '../../../data/models/premade_nudge.dart';
import '../../../data/premade_nudges_data.dart';

import '../../../data/models/nudge_model.dart'; // for Nudge, NudgeType, NudgeStatus
import 'nudge_edit_screen.dart';                // your existing editor
import 'my_nudges_screen.dart';                  // optional, just the appbar button

class PremadeNudgesScreen extends StatefulWidget {
  const PremadeNudgesScreen({super.key});

  @override
  State<PremadeNudgesScreen> createState() => _PremadeNudgesScreenState();
}

class _PremadeNudgesScreenState extends State<PremadeNudgesScreen> {
  final TextEditingController _search = TextEditingController();
  int _selectedFilterIndex = 0;

  // Treat your premades as PremadeNudge (this matches your data source)
  late final List<PremadeNudge> _allPremades =
      List<PremadeNudge>.from(PremadeNudgesData.allNudges);

  // Keyword-based filters (no category field required on PremadeNudge)
  final List<_FilterSpec> _filters = const [
    _FilterSpec('All', []),
    _FilterSpec('Hydration', ['water', 'hydrate', 'drink']),
    _FilterSpec('Movement', ['walk', 'steps', 'stretch', 'stand', 'move', 'exercise', 'push-up', 'run']),
    _FilterSpec('Mindfulness', ['breath', 'meditat', 'mindful']),
    _FilterSpec('Gratitude', ['gratitude', 'grateful', 'thank']),
    _FilterSpec('Sleep', ['sleep', 'bed', 'wind down']),
    _FilterSpec('Focus', ['focus', 'study', 'deep work', 'pomodoro']),
    _FilterSpec('Productivity', ['break', 'task', 'plan', 'organize']),
    _FilterSpec('Health', ['posture', 'sunlight', 'fruit', 'veggie']),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<PremadeNudge> get _filtered {
    final q = _search.text.trim().toLowerCase();

    final withSearch = q.isEmpty
        ? _allPremades
        : _allPremades.where((n) {
            final t = ('${n.title} ${n.description}').toLowerCase();
            return t.contains(q);
          }).toList();

    final filter = _filters[_selectedFilterIndex];
    if (filter.keywords.isEmpty) return withSearch;

    return withSearch.where((n) {
      final t = ('${n.title} ${n.description}').toLowerCase();
      return filter.keywords.any((k) => t.contains(k));
    }).toList();
  }

  // Convert a PremadeNudge to a Nudge template required by your editor
  Nudge _toNudgeTemplate(PremadeNudge p) {
    return Nudge(
      id: 'tmpl_${p.id}',                // any temp id; edit screen will save a real one
      title: p.title,
      description: p.description,
      category: 'Personal',              // no category on PremadeNudge; use default
      icon: _iconFor(p.title),           // quick emoji guess
      isActive: true,
      createdAt: p.createdAt,
      type: NudgeType.personal,
      createdBy: 'local',                // or your current user id if you have one
      status: NudgeStatus.active,
      streak: 0,
      isAIGenerated: false,
    );
  }

  String _iconFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('water') || t.contains('drink')) return '💧';
    if (t.contains('walk') || t.contains('steps')) return '🚶';
    if (t.contains('study') || t.contains('focus')) return '📚';
    if (t.contains('sleep') || t.contains('bed')) return '😴';
    if (t.contains('meditat') || t.contains('mindful') || t.contains('breath')) return '🧘';
    if (t.contains('gratitude')) return '🙏';
    return '🔔';
  }

  Future<void> _openEditor(PremadeNudge p) async {
    final template = _toNudgeTemplate(p);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NudgeEditScreen(template: template)),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved “${p.title}”')),
      );
      // If your edit screen already updates the cubit/state that Home/Personal read,
      // nothing else is needed here. If you have an explicit reload method, call it.
      // context.read<NudgesCubit>().reload(); // (only if you have one)
      setState(() {}); // harmless refresh of this page
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Browse Habits'),
        backgroundColor: AppTheme.cardWhite,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyNudgesScreen()),
              );
            },
            icon: const Icon(Icons.list_alt_rounded),
            label: const Text('My Nudges'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _SearchField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              onClear: () {
                _search.clear();
                setState(() {});
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filters row
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                final selected = i == _selectedFilterIndex;
                return ChoiceChip(
                  label: Text(f.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedFilterIndex = i),
                  selectedColor: AppTheme.primaryPurple.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: selected ? AppTheme.primaryPurple : AppTheme.textDark,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          // Results
          Expanded(
            child: results.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = results[i];
                      return _PremadeCard(
                        title: p.title,
                        description: p.description,
                        onTap: () => _openEditor(p), // open editor first
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterSpec {
  final String label;
  final List<String> keywords;
  const _FilterSpec(this.label, this.keywords);
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search nudges',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClear,
                tooltip: 'Clear',
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _PremadeCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _PremadeCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap, // tap whole card = open editor
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primaryPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        )),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onTap, // plus button also opens editor
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Edit & add',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textLight),
            SizedBox(height: 12),
            Text('No results', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            SizedBox(height: 6),
            Text('Try a different search or filter.', style: TextStyle(color: AppTheme.textGray)),
          ],
        ),
      ),
    );
  }
}
