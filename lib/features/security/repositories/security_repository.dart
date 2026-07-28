import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../out_pass/models/out_pass_model.dart';

final securityRepositoryProvider = Provider((ref) => SecurityRepository(Supabase.instance.client));

final approvedRequestsProvider = StreamProvider<List<OutPassModel>>((ref) {
  return ref.read(securityRepositoryProvider).getApprovedRequests();
});

class SecurityRepository {
  final SupabaseClient _supabase;
  SecurityRepository(this._supabase);

  // Fetch only approved requests for the security guard
  Stream<List<OutPassModel>> getApprovedRequests() {
    return _supabase
        .from('out_pass_requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'accepted')
        .map((data) => data.map((json) => OutPassModel.fromJson(json)).toList());
  }

  // Mark request as exited
  Future<void> markAsExited(String passId) async {
    await _supabase
        .from('out_pass_requests')
        .update({'status': 'exited'})
        .eq('id', passId);
  }
}