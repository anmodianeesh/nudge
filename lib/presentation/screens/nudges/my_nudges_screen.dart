import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nudge/business_logic/cubits/nudges_cubit.dart';
import 'package:nudge/business_logic/states/nudges_state.dart';
import 'package:nudge/core/theme/app_theme.dart';
import 'package:nudge/presentation/screens/nudges/premade_nudges_screen.dart';

class MyNudgesScreen extends StatelessWidget {
  const MyNudgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1, // Only Active for now (Paused tab removed)
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Nudges', style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),),
      
          backgroundColor: AppTheme.cardWhite,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Add from Premade',
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PremadeNudgesScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<NudgesCubit, NudgesState>(
          builder: (context, state) {
            final active = state.activeMyNudges;

            return TabBarView(
              children: [
                _MyNudgesList(
                  items: active,
                  emptyTitle: 'No active nudges',
                  emptySubtitle: 'Add from premade or create your own.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MyNudgesList extends StatelessWidget {
  final List items;
  final String emptyTitle;
  final String emptySubtitle;

  const _MyNudgesList({
    required this.items,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NudgesCubit>().state;

    if (items.isEmpty) {
      return _Empty(
        title: emptyTitle,
        subtitle: emptySubtitle,
        action: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PremadeNudgesScreen()),
          ),
          child: const Text('Browse premade'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final n = items[i];
        final id = n.id as String;
        final isCompleted = state.isCompletedToday(id);
        final isSnoozed = state.isSnoozed(id);

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              n.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(n.category),
            leading: Icon(
              isSnoozed
                  ? Icons.snooze // will not be toggled because we removed actions
                  : (isCompleted ? Icons.check_circle : Icons.lightbulb_outline),
              color: isCompleted ? Colors.green : AppTheme.primaryPurple,
            ),
            trailing: IconButton(
              tooltip: isCompleted ? 'Unmark today' : 'Mark done today',
              icon: Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
              onPressed: () => context.read<NudgesCubit>().markDoneToday(id),
            ),
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  const _Empty({required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
