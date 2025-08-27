import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }

  void _navigateToOnboarding() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flash_on_rounded,
                size: 80,
                color: AppTheme.primaryPurple,
              ),
              SizedBox(height: 16),
              Text(
                'Nudge',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your AI Behavioral Companion',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}