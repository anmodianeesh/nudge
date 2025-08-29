// lib/presentation/screens/nudges/premade_nudges_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/premade_nudges_data.dart';
import '../../../data/models/premade_nudge.dart';
import '../../../data/storage/my_nudges_storage.dart';
import 'my_nudges_screen.dart';

class PremadeNudgesScreen extends StatelessWidget {
  const PremadeNudgesScreen({super.key});

  Future<void> _add(BuildContext context, PremadeNudge n) async {
    await MyNudgesStorage.addFromLibrary(n);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added “${n.title}” to My Nudges')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: PremadeNudgesData.allNudges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final n = PremadeNudgesData.allNudges[i];
          return _PremadeCard(
            nudge: n,

            onAdd: () => _add(context, n),
          );
        },
      ),
    );
  }
}

class _PremadeCard extends StatelessWidget {
  final PremadeNudge nudge;
  final VoidCallback onAdd;

  const _PremadeCard({required this.nudge, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onAdd,
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
                    Text(nudge.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        )),
                    const SizedBox(height: 6),
                    Text(
                      nudge.description,
                      style: const TextStyle(color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
