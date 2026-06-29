import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../services/staff_service.dart';
import '../../state/active_branch_provider.dart';
import '../../widgets/animated_list_item.dart';
import 'staff_editor_screen.dart';

final staffListProvider =
    FutureProvider.autoDispose<List<Profile>>((ref) async {
  return staffService.listAll();
});

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffListProvider);
    final branches = ref.watch(branchesProvider).value ?? const [];
    String branchName(String? id) {
      for (final b in branches) {
        if (b.id == id) return b.name;
      }
      return '—';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Users & Access')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users yet.'));
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final u = users[i];
              return AnimatedListItem(
                index: i,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: u.isAdmin ? Colors.brown.shade300 : Colors.grey.shade300,
                    child: Icon(u.isAdmin ? Icons.shield : Icons.person, size: 20),
                  ),
                  title: Text(u.fullName?.isNotEmpty == true ? u.fullName! : (u.email ?? u.id)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${u.isAdmin ? 'Admin' : 'Staff'} • ${branchName(u.branchId)}'),
                      const SizedBox(height: 4),
                      if (u.isAdmin)
                        const Text('Full access (all modules)',
                            style: TextStyle(fontSize: 12, color: Colors.grey))
                      else
                        Wrap(spacing: 4, runSpacing: 4, children: _chips(u)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: u.isAdmin ? null : const Icon(Icons.edit_outlined),
                  onTap: u.isAdmin
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => StaffEditorScreen(user: u)),
                          ).then((_) => ref.invalidate(staffListProvider)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _chips(Profile u) {
    final mods = <String, bool>{
      'Dashboard': u.canAccessDashboard,
      'Sales': u.canAccessSales,
      'Delivery': u.canAccessDelivery,
      'Expenses': u.canAccessExpenses,
      'Reports': u.canAccessReports,
    };
    final on = mods.entries.where((e) => e.value).map((e) => e.key).toList();
    if (on.isEmpty) {
      return [const Text('No access', style: TextStyle(fontSize: 12, color: Colors.red))];
    }
    return on
        .map((m) => Chip(
              label: Text(m, style: const TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ))
        .toList();
  }
}