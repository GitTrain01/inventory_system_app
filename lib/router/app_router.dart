import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/supabase_client.dart';
import '../state/auth_provider.dart';
import '../state/profile_provider.dart';
import '../screens/login/login_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/dashboard_admin/admin_dashboard.dart';
import '../screens/dashboard_staff/staff_dashboard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Pokes the router to re-check `redirect` whenever auth or profile changes.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.listen(profileProvider, (_, __) => refresh.value++);

  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = supabase.auth.currentSession != null;
      final loc = state.matchedLocation;
      final atLogin = loc == '/login';

      if (!loggedIn) return atLogin ? null : '/login';

      // Logged in — route by role once the profile finishes loading.
      return ref.read(profileProvider).when(
        loading: () => loc == '/loading' ? null : '/loading',
        error: (_, __) => atLogin ? null : '/login',
        data: (profile) {
          if (profile == null) return atLogin ? null : '/login';
          final home = profile.isAdmin ? '/admin' : '/staff';
          return (atLogin || loc == '/loading') ? home : null;
        },
      );
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/loading', builder: (_, __) => const LoadingScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard()),
      GoRoute(path: '/staff', builder: (_, __) => const StaffDashboard()),
    ],
  );
});