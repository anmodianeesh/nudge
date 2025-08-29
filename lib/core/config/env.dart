class Env {
  // Flip this per build flavor
  static const bool useMockApi = true;

  // Only used when useMockApi == false
  static const String apiBaseUrl = 'https://api.yourdomain.com';
  static const String apiAuthToken = ''; // your JWT if applicable
}
