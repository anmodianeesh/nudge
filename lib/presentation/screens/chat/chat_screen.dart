import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('AI Coach'),
        backgroundColor: AppTheme.cardWhite,
      ),
      body: const Center(
        child: Text(
          'AI Chat Screen\n(Building this next)',
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