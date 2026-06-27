import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../state/delivery_providers.dart';
import 'delivery_plan_editor_screen.dart';

class DeliveryPlansScreen extends ConsumerWidget {
  const DeliveryPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(deliveryPlansProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Plans')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DeliveryPlanEditorScreen(date: DateTime.now())),
        ).then((_) => ref.invalidate(deliveryPlansProvider)),
        icon: const Icon(Icons.add),
        label: const Text('New plan'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(child: Text('No delivery plans yet. Tap “New plan”.'));
          }
          return ListView.separated(
            itemCount: plans.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = plans[i];
              return ListTile(
                title: Text(DateFormat('EEE, MMM d, yyyy').format(p.planDate)),
                subtitle: (p.notes == null || p.notes!.isEmpty) ? null : Text(p.notes!),
                trailing: _StatusChip(status: p.status),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DeliveryPlanEditorScreen(date: p.planDate)),
                ).then((_) => ref.invalidate(deliveryPlansProvider)),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    final delivered = status == 'delivered';
    return Chip(
      label: Text(delivered ? 'Delivered' : 'Draft'),
      backgroundColor: delivered ? Colors.green.shade100 : Colors.orange.shade100,
      visualDensity: VisualDensity.compact,
    );
  }
}