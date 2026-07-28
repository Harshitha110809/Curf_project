import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Fetches the user profile from your custom table using the secure auth ID
  Future<UserModel?> getCurrentUserProfile() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('auth_user_id', session.user.id)
          .maybeSingle();

      if (data == null) return null;
      return UserModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Registers the user in Supabase Auth, then saves their role data to your table
  Future<void> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? registrationNumber,
    String? roomDetails, // 1. NEW FIELD ADDED HERE
    String? linkedStudentId,
  }) async {
    // 1. Create secure authentication identity
    final AuthResponse response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) throw Exception('Registration failed.');

    try {
      // 2. Clean up data maps to avoid database constraint crashes
      final profileData = {
        'auth_user_id': user.id,
        'full_name': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role.trim(),
        'verified': false,
        // Only include these if they are not blank strings
        if (registrationNumber != null && registrationNumber.trim().isNotEmpty)
          'registration_number': registrationNumber.trim(),
        if (roomDetails != null && roomDetails.trim().isNotEmpty)
          'room_details': roomDetails.trim(), // 2. SAVES TO DATABASE HERE
        if (linkedStudentId != null && linkedStudentId.trim().isNotEmpty)
          'linked_student_id': linkedStudentId.trim(),
      };

      // Try inserting into your public.users table
      await _supabase.from('users').insert(profileData);
    } catch (dbError) {
      // ANTI-GHOST ESCAPE: If the database rejects the insert, sign out immediately
      await _supabase.auth.signOut();

      // Force the exact database error message to bubble up to the screen
      throw Exception('Database Insert Failed!\nReason: $dbError');
    }
  }

  Future<void> loginUser({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}