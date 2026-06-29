import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/branches_service.dart';
import '../../state/active_branch_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(activeBranchProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: branch == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Night Shift Mode'),
                  subtitle: Text(
                      'Two independent shifts (Day/Night) per day for ${branch.name}. '
                      'Night sales file under the day they started.'),
                  value: branch.nightShiftEnabled,
                  onChanged: (v) async {
                    await branchesService.setNightShift(branch.id, v);
                    ref.invalidate(branchesProvider); // refresh active branch
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    branch.nightShiftEnabled
                        ? 'On: the Sales Worksheet requires a Day/Night choice; Night defaults to yesterday.'
                        : 'Off: everything is treated as a single Day shift.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
    );
  }
}