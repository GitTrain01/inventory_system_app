import '../core/supabase_client.dart';
import '../models/branch.dart';

class BranchesService {
  Future<List<Branch>> listActive() async {
    final rows = await supabase
        .from('branches')
        .select()
        .eq('is_active', true)
        .order('name');
    return rows.map<Branch>((r) => Branch.fromJson(r)).toList();
  }

  Future<void> setNightShift(String branchId, bool enabled) async {
    await supabase.from('branches').update({
      'night_shift_enabled': enabled,
    }).eq('id', branchId);
  }
  Future<void> createBranch({
    required String name,
    String? address,
  }) async {
    await supabase.from('branches').insert({
      'name': name,
      'address': address,
      'is_active': true,
      'night_shift_enabled': false,
    });
  }

  Future<void> updateBranch({
    required String id,
    required String name,
    String? address,
    required bool isActive,
  }) async {
    await supabase.from('branches').update({
      'name': name,
      'address': address,
      'is_active': isActive,
    }).eq('id', id);
  }

  /// All branches incl. inactive (management view).
  Future<List<Map<String, dynamic>>> listAll() async {
    final rows = await supabase.from('branches').select().order('name');
    return rows.cast<Map<String, dynamic>>();
  }
}

final branchesService = BranchesService();