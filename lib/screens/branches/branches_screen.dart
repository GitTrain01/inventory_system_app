import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/branches_service.dart';
import '../../state/active_branch_provider.dart';
import '../../widgets/animated_list_item.dart';

final _allBranchesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return branchesService.listAll();
});

class BranchesScreen extends ConsumerWidget {
  const BranchesScreen({super.key});

  Future<void> _dialog(BuildContext context, WidgetRef ref, {Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: existing?['name'] as String? ?? '');
    final address = TextEditingController(text: existing?['address'] as String? ?? '');
    bool active = (existing?['is_active'] ?? true) as bool;
    String? err;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'New branch' : 'Edit branch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Address (optional)')),
              if (existing != null) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  onChanged: (v) => setLocal(() => active = v),
                ),
              ],
              if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) {
                  setLocal(() => err = 'Name is required.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final addr = address.text.trim().isEmpty ? null : address.text.trim();
      if (existing == null) {
        await branchesService.createBranch(name: name.text.trim(), address: addr);
      } else {
        await branchesService.updateBranch(
            id: existing['id'] as String, name: name.text.trim(), address: addr, isActive: active);
      }
      ref.invalidate(_allBranchesProvider);
      ref.invalidate(branchesProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_allBranchesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Branches')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _dialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New branch'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rows) {
          if (rows.isEmpty) return const Center(child: Text('No branches.'));
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final b = rows[i];
              final active = (b['is_active'] ?? true) as bool;
              final night = (b['night_shift_enabled'] ?? false) as bool;
              return AnimatedListItem(
                index: i,
                child: ListTile(
                  leading: Icon(Icons.store_outlined, color: active ? null : Colors.grey),
                  title: Text(b['name'] as String,
                      style: TextStyle(color: active ? null : Colors.grey)),
                  subtitle: Text([
                    if (b['address'] != null && (b['address'] as String).isNotEmpty) b['address'],
                    if (night) '🌙 Night shift on',
                    if (!active) 'Inactive',
                  ].join(' • ')),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _dialog(context, ref, existing: b),
                ),
              );
            },
          );
        },
      ),
    );
  }
}