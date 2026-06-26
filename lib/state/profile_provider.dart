import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../models/user_profile.dart';
import 'auth_provider.dart';

/// Loads the signed-in user's profile row. Re-runs on every auth change.
final profileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authStateProvider); // re-fetch when auth state changes
  final session = supabase.auth.currentSession;
  if (session == null) return null;

  final data = await supabase
      .from('user_profiles')
      .select()
      .eq('id', session.user.id) // ⚠️ change 'id' to 'user_id' if that's your linking column
      .maybeSingle();

  return data == null ? null : Profile.fromJson(data);
});