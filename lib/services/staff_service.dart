import '../core/supabase_client.dart';
import '../models/user_profile.dart';

class StaffService {
  /// All profiles, admins first, then by name.
  Future<List<Profile>> listAll() async {
    final rows = await supabase
        .from('user_profiles')
        .select()
        .order('role')
        .order('full_name', nullsFirst: false);
    return rows.map<Profile>((r) => Profile.fromJson(r)).toList();
  }

  Future<void> updateAccess({
    required String id,
    required String? branchId,
    required bool dashboard,
    required bool delivery,
    required bool sales,
    required bool expenses,
    required bool reports,
  }) async {
    await supabase.from('user_profiles').update({
      'branch_id': branchId,
      'can_access_dashboard': dashboard,
      'can_access_delivery': delivery,
      'can_access_sales': sales,
      'can_access_expenses': expenses,
      'can_access_reports': reports,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}

final staffService = StaffService();