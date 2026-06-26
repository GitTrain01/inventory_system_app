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
}

final branchesService = BranchesService();