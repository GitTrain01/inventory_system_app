import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class AuthService {
  User? get currentUser => supabase.auth.currentUser;
  Session? get currentSession => supabase.auth.currentSession;

  Future<void> signIn({required String email, required String password}) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => supabase.auth.signOut();
}

final authService = AuthService();