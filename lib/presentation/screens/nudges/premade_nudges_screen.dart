import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/nudge.dart';
import 'package:nudge/data/premade_nudges_data.dart';

class PremadeNudgesScreen extends StatelessWidget {
  const PremadeNudgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nudges = PremadeNudgesData.allNudges;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Browse Habits'),
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: nudges.length,
        itemBuilder: (context, index) {
          final Nudge nudge = nudges[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: AppTheme.primaryPurple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nudge.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              nudge.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${nudge.title} added to My Nudges'),
                              backgroundColor: AppTheme.primaryPurple,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nudge.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGray,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}