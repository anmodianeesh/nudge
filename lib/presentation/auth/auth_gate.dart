// lib/presentation/auth/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/supabase_service.dart';
import '../../../business_logic/cubits/nudges_cubit.dart';

import '../navigation/root_nav.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

/// Toggle this while testing onboarding/login flows.
const bool kForceOnboarding = true;

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Pull cloud data when auth state changes to signed-in.
    SupabaseService.client.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session != null && mounted) {
        context.read<NudgesCubit>().loadFromCloud();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Force Splash -> Onboarding while testing
    if (kForceOnboarding) {
      return const SplashToOnboarding();
    }

    final session = SupabaseService.client.auth.currentSession;
    if (session != null) {
      context.read<NudgesCubit>().loadFromCloud();
      return const RootNav();
    }
    return const SplashToOnboarding();
  }
}

class SplashToOnboarding extends StatefulWidget {
  const SplashToOnboarding({super.key});
  @override
  State<SplashToOnboarding> createState() => _SplashToOnboardingState();
}

class _SplashToOnboardingState extends State<SplashToOnboarding> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
