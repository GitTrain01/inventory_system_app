import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../state/active_branch_provider.dart';
import '../../widgets/branch_switcher.dart';
import '../products/products_screen.dart';
import '../stock/stock_screen.dart';
import '../delivery/delivery_plans_screen.dart';
import '../delivery/delivery_confirm_screen.dart';
import '../sales/sales_worksheet_screen.dart';

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
            if (branch != null) Text(branch.name, style: const TextStyle(fontSize: 12)),
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
      body: ListView(
        children: [
          ListTile( 
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Products'),
            subtitle: const Text('Catalog, sub-categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.warehouse_outlined),
            title: const Text('Live Stock'),
            subtitle: const Text('Count and adjust quantities'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StockScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text('Delivery Plans'),
            subtitle: const Text('Plan a restock'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const DeliveryPlansScreen())),
         ),
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
            subtitle: const Text('Closing counts & sold'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SalesWorksheetScreen())),
          ),
        ],
      ),
    );
  }
}