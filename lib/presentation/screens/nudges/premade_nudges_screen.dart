import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PremadeNudgesScreen extends StatelessWidget {
  const PremadeNudgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Browse Habits'),
        backgroundColor: AppTheme.cardWhite,
      ),
      body: const Center(
        child: Text(
          'Premade Habits Library\n(Building this next)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.textGray,
          ),
        ),
      ),
    );
  }
}