import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/subcategory.dart';
import '../../services/subcategories_service.dart';
import '../../state/active_branch_provider.dart';
import '../../state/catalog_providers.dart';

class SubcategoryManagerScreen extends ConsumerWidget {
  const SubcategoryManagerScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(subcategoriesProvider);
    ref.invalidate(productsProvider); // names may have changed on products
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subcategoriesProvider);
    final branch = ref.watch(activeBranchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sub-categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = await _promptName(context, title: 'New sub-category');
          if (name != null && branch != null) {
            await subcategoriesService.add(branch.id, name);
            await _refresh(ref);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (subs) {
          if (subs.isEmpty) {
            return const Center(child: Text('No sub-categories yet.'));
          }
          return ListView(
            children: subs.map((s) => _row(context, ref, s, branch?.id)).toList(),
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, Subcategory s, String? branchId) {
    return ListTile(
      title: Text(s.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final newName =
                  await _promptName(context, title: 'Rename', initial: s.name);
              if (newName != null && branchId != null && newName != s.name) {
                await subcategoriesService.rename(
                    id: s.id, branchId: branchId, oldName: s.name, newName: newName);
                await _refresh(ref);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Delete “${s.name}”?'),
                  content: const Text(
                      'Products in this sub-category will be moved to “Uncategorized”.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true && branchId != null) {
                await subcategoriesService.delete(
                    id: s.id, branchId: branchId, name: s.name);
                await _refresh(ref);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _promptName(BuildContext context,
      {required String title, String? initial}) {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              Navigator.pop(context, v.isEmpty ? null : v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}