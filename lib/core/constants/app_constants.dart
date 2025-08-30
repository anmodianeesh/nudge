class AppConstants {
  // App Info
  static const String appName = 'Nudge';
  static const String appTagline = 'Your AI Behavioral Companion';
  
  // API (we'll add these later)

  static const String supabaseUrl = 'https://gxrdowsojofpocspqoje.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd4cmRvd3Nvam9mcG9jc3Bxb2plIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY0MjI5NDcsImV4cCI6MjA3MTk5ODk0N30.msW84Kpiowvk3mifOJaqfazfPxSS_N1_rdoW7Z0koNs';
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