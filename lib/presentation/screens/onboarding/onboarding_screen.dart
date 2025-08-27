import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.psychology_rounded,
                size: 80,
                color: AppTheme.primaryPurple,
              ),
              const SizedBox(height: 24),
              const Text(
                'Build Better Habits',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Get personalized nudges from your AI behavioral companion to form micro-habits that stick.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textGray,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'Get Started',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}