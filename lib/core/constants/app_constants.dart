class AppConstants {
  // App Info
  static const String appName = 'Nudge';
  static const String appTagline = 'Your AI Behavioral Companion';
  
  // API (we'll add these later)
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String openaiApiKey = 'YOUR_OPENAI_API_KEY';
  
  // Routes
  static const String splashRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const String chatRoute = '/chat';
  static const String premadeRoute = '/premade';
  static const String nudgesListRoute = '/nudges';
  static const String profileRoute = '/profile';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
}