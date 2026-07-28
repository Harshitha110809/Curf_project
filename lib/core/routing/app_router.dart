import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Added for the security check

import 'package:curf_app/features/auth/screens/login_screen.dart';
import 'package:curf_app/features/auth/screens/register_screen.dart';
import 'package:curf_app/features/student/screens/student_dashboard.dart';
import 'package:curf_app/features/out_pass/screens/out_pass_request_screen.dart';
import 'package:curf_app/features/warden/screens/warden_dashboard.dart';
import 'package:curf_app/features/security/screens/gate_security_dashboard.dart';
import 'package:curf_app/features/parent/screens/parent_dashboard.dart';

// This watches Supabase auth state so the router refreshes automatically on login/logout
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider); // Watch auth state

  return GoRouter(
    initialLocation: '/login',

    // THE BOUNCER: Intercepts every screen change to ensure strict role-based security
    redirect: (BuildContext context, GoRouterState state) async {
      final supabase = Supabase.instance.client;
      final isAuth = supabase.auth.currentUser != null;
      final location = state.matchedLocation;
      final isLoggingIn = location == '/login' || location == '/register';

      // 1. If not logged in, force to login (unless already on login/register)
      if (!isAuth) {
        return isLoggingIn ? null : '/login';
      }

      // 2. Role lookup and strict routing if they are logged in
      try {
        final userProfile = await supabase
            .from('users')
            .select('role')
            .eq('auth_user_id', supabase.auth.currentUser!.id)
            .maybeSingle();

        if (userProfile == null) return '/login'; // Failsafe

        final role = userProfile['role'].toString().toLowerCase().trim();

        // 3. Auto-route to correct dashboard upon login
        if (isLoggingIn) {
          if (role == 'warden') return '/warden';
          if (role == 'security' || role == 'guard') return '/security';
          if (role == 'parent') return '/parent';
          return '/student';
        }

        // 4. PREVENT SNEAKING IN: Lockout logic
        // If they try to type a URL they shouldn't access, kick them back to their dashboard.
        // Notice we explicitly ALLOW students to access '/new-out-pass'
        if (role == 'student' && (location == '/warden' || location == '/security' || location == '/parent')) return '/student';
        if (role == 'warden' && (location == '/student' || location == '/new-out-pass' || location == '/security' || location == '/parent')) return '/warden';
        if (role == 'security' && (location == '/student' || location == '/new-out-pass' || location == '/warden' || location == '/parent')) return '/security';
        if (role == 'parent' && (location == '/student' || location == '/new-out-pass' || location == '/warden' || location == '/security')) return '/parent';

      } catch (e) {
        // If anything goes wrong fetching the role, send back to login
        return '/login';
      }

      return null; // All good, allow navigation
    },

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/student', builder: (context, state) => const StudentDashboard()),
      GoRoute(path: '/new-out-pass', builder: (context, state) => const OutPassRequestScreen()),
      GoRoute(path: '/warden', builder: (context, state) => const WardenDashboard()),
      GoRoute(path: '/security', builder: (context, state) => const GateSecurityDashboard()),
      GoRoute(path: '/parent', builder: (context, state) => const ParentDashboard()),
    ],
  );
});