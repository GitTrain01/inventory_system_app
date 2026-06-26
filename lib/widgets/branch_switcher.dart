import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/active_branch_provider.dart';

void showBranchSwitcher(BuildContext context, WidgetRef ref) {
  final branches = ref.read(branchesProvider).value ?? const [];
  final active = ref.read(activeBranchProvider);

  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Switch branch',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...branches.map((b) => ListTile(
                title: Text(b.name),
                subtitle: b.address == null ? null : Text(b.address!),
                trailing: b.id == active?.id ? const Icon(Icons.check) : null,
                onTap: () {
                  ref.read(selectedBranchIdProvider.notifier).select(b.id);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    ),
  );
}