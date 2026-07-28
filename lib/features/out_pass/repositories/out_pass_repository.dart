import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/out_pass_model.dart';
import '../../auth/providers/auth_providers.dart';

final outPassRepositoryProvider = Provider((ref) => OutPassRepository(Supabase.instance.client));

// Provider for Student Dashboard
final studentOutPassesProvider = StreamProvider<List<OutPassModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || user.id == null) return Stream.value([]);
  return ref.read(outPassRepositoryProvider).getStudentPasses(user.id!);
});

// Provider for Warden Dashboard
final wardenRequestsProvider = StreamProvider<List<OutPassModel>>((ref) {
  return ref.read(outPassRepositoryProvider).getWardenRequests();
});

class OutPassRepository {
  final SupabaseClient _supabase;
  OutPassRepository(this._supabase);

  // Used by Student Request Screen
  Future<void> submitOutPassRequest(OutPassModel outPass) async {
    await _supabase.from('out_pass_requests').insert(outPass.toJson());
  }

  // Used by Student Dashboard
  Stream<List<OutPassModel>> getStudentPasses(String studentId) {
    return _supabase
        .from('out_pass_requests')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .map((data) => data.map((json) => OutPassModel.fromJson(json)).toList());
  }

  // Used by Warden Dashboard
  Stream<List<OutPassModel>> getWardenRequests() {
    return _supabase
        .from('out_pass_requests')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => OutPassModel.fromJson(json)).toList());
  }

  // THIS IS THE MISSING METHOD THAT CAUSED YOUR ERROR
  Future<void> updateOutPassStatus(String passId, String newStatus) async {
    await _supabase
        .from('out_pass_requests')
        .update({'status': newStatus})
        .eq('id', passId);
  }
}