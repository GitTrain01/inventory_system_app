import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/branch.dart';
import '../services/branches_service.dart';
import 'profile_provider.dart';

/// All active branches (admin switcher reads this).
final branchesProvider = FutureProvider<List<Branch>>((ref) async {
  return branchesService.listActive();
});

/// Holds ONLY the admin's manually-picked branch id.
/// Watches nothing, so it survives branch/profile reloads.
class SelectedBranchId extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String id) => state = id;
}

final selectedBranchIdProvider =
    NotifierProvider<SelectedBranchId, String?>(SelectedBranchId.new);

/// The currently active branch. Every later query filters by this.
final activeBranchProvider = Provider<Branch?>((ref) {
  final profile = ref.watch(profileProvider).value;
  final branches = ref.watch(branchesProvider).value ?? const <Branch>[];
  final selectedId = ref.watch(selectedBranchIdProvider);

  if (profile == null || branches.isEmpty) return null;

  // Staff: locked to their own branch.
  if (!profile.isAdmin) {
    return _byId(branches, profile.branchId) ?? branches.first;
  }
  // Admin: honor a valid manual pick, else default to the first branch.
  return _byId(branches, selectedId) ?? branches.first;
});

Branch? _byId(List<Branch> list, String? id) {
  for (final b in list) {
    if (b.id == id) return b;
  }
  return null;
}