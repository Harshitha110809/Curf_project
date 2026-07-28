import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  ref.watch(authStateProvider); // Re-runs when user logs in/out
  final repo = ref.watch(authRepositoryProvider);
  return await repo.getCurrentUserProfile();
});