import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../state/active_branch_provider.dart';

class StaffDashboard extends ConsumerWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(activeBranchProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Staff Dashboard'),
            if (branch != null)
              Text(branch.name, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: authService.signOut),
        ],
      ),
      body: Center(
        child: Text(branch == null ? 'Loading branch…' : 'Your branch: ${branch.name}'),
      ),
    );
  }
}