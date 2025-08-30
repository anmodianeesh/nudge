import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  final _auth = SupabaseService.client.auth;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    // You can also collect name and store in a 'profiles' table later.
    return await _auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Session? currentSession() => _auth.currentSession;
  User? currentUser() => _auth.currentUser;
}
