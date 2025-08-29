import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'personal_nudges_screen.dart';
import 'group_nudges_screen.dart';
import 'friend_nudges_screen.dart';

class MyNudgesScreen extends StatelessWidget {
  const MyNudgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_Category>[
      _Category(
        title: 'Personal',
        subtitle: 'Your habits & goals',
        icon: Icons.person_rounded,
        color: AppTheme.primaryPurple,
        builder: (_) => const PersonalNudgesScreen(),
      ),
      _Category(
        title: 'Family',
        subtitle: 'Nudges with family',
        icon: Icons.family_restroom_rounded,
        color: Colors.orange,
        builder: (_) => const GroupNudgesScreen(), // reuse group screen
      ),
      _Category(
        title: 'Friends',
        subtitle: 'Accountability buddies',
        icon: Icons.diversity_1_rounded,
        color: Colors.green,
        builder: (_) => const FriendNudgesScreen(),
      ),
      _Category(
        title: 'Teams',
        subtitle: 'School, clubs, work',
        icon: Icons.groups_rounded,
        color: Colors.blue,
        builder: (_) => const GroupNudgesScreen(), // reuse group screen
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('My Nudges'),
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Choose a category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // --- Grid of category cards (2 columns) ---
            Expanded(
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, i) => _NudgeCategoryCard(item: items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------ */
/* Models & widgets                                                    */
/* ------------------------------------------------------------------ */

class _Category {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  _Category({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
  });
}

class _NudgeCategoryCard extends StatelessWidget {
  final _Category item;
  const _NudgeCategoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardWhite,
      elevation: 0.5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderGray),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: item.builder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Round icon
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 28),
              ),
              const Spacer(),
              // Title
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppTheme.textGray, height: 1.2),
              ),
              const SizedBox(height: 8),
              // Chevon row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textGray),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
