import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../state/active_branch_provider.dart';
import '../../state/profile_provider.dart';
import '../stock/stock_screen.dart';
import '../delivery/delivery_confirm_screen.dart';
import '../sales/sales_worksheet_screen.dart';

class StaffDashboard extends ConsumerWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(activeBranchProvider);
    final profile = ref.watch(profileProvider).value;
    final canDeliver = profile?.canAccessDelivery ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Staff Dashboard'),
            if (branch != null) Text(branch.name, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: authService.signOut),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.warehouse_outlined),
            title: const Text('Live Stock'),
            subtitle: Text(branch == null ? '' : 'Counting for ${branch.name}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const StockScreen())),
          ),
          if (canDeliver)
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Confirm Delivery'),
              subtitle: const Text('Any branch'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const DeliveryConfirmScreen())),
            ),
          ListTile(
              leading: const Icon(Icons.point_of_sale_outlined),
              title: const Text('Sales Worksheet'),
              subtitle: const Text('Enter closing counts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SalesWorksheetScreen())),
            ),
        ],
      ),
    );
  }
}