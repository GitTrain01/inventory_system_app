import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../state/active_branch_provider.dart';
import '../../widgets/branch_switcher.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(activeBranchProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Dashboard'),
            if (branch != null)
              Text(branch.name, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch branch',
            onPressed: () => showBranchSwitcher(context, ref),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: authService.signOut),
        ],
      ),
      body: Center(
        child: Text(branch == null ? 'Loading branch…' : 'Active branch: ${branch.name}'),
      ),
    );
  }
}