import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../state/active_branch_provider.dart';
import '../state/profile_provider.dart';
import '../state/theme_provider.dart';
import '../screens/products/products_screen.dart';
import '../screens/products/subcategory_manager_screen.dart';
import '../screens/stock/stock_screen.dart';
import '../screens/delivery/delivery_plans_screen.dart';
import '../screens/delivery/delivery_confirm_screen.dart';
import '../screens/delivery/delivery_history_screen.dart';
import '../screens/sales/sales_worksheet_screen.dart';
import '../screens/sales/cash_count_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/reports/discrepancy_screen.dart';
import '../screens/reports/sales_history_screen.dart';
import '../screens/reports/opening_stock_screen.dart';
import '../screens/staff/staff_list_screen.dart';
import '../screens/branches/branches_screen.dart';
import '../screens/settings/settings_screen.dart';

/// Identifies which screen is showing, so the drawer can highlight it.
enum NavKey {
  dashboard, liveStock, discrepancy, products, deliveryPlan, expenseHistory,
  deliveryHistory, subcategories, staff, branches, confirmDelivery, salesHistory,
  openingStock, sales, cashCount, expenses, settings, none,
}

class AppDrawer extends ConsumerWidget {
  final NavKey current;
  const AppDrawer({super.key, this.current = NavKey.dashboard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final isAdmin = profile?.isAdmin ?? false;
    final branch = ref.watch(activeBranchProvider);
    final branches = ref.watch(branchesProvider).value ?? const [];
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    // Push a screen unless we're already on it; dashboard always just pops.
    void go(NavKey key, Widget screen) {
      Navigator.pop(context);
      if (key == current) return; // already here
      if (key == NavKey.dashboard) return; // popping returns to dashboard
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.brickRed,
                    child: Icon(Icons.storefront, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('4C SnackHouse',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(branch?.name ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isAdmin && branches.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: DropdownButtonFormField<String>(
                  initialValue:
                      branches.any((b) => b.id == branch?.id) ? branch?.id : null,
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.store_outlined, size: 18),
                  ),
                  items: branches
                      .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) ref.read(selectedBranchIdProvider.notifier).select(v);
                  },
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  if (isAdmin) ...[
                    _section('USEFUL TOOLS'),
                    _item(context, NavKey.dashboard, Icons.dashboard_outlined, 'Dashboard',
                        () => go(NavKey.dashboard, const SizedBox())),
                    _item(context, NavKey.liveStock, Icons.warehouse_outlined, 'Live Stock',
                        () => go(NavKey.liveStock, const StockScreen())),
                    _item(context, NavKey.discrepancy, Icons.fact_check_outlined, 'Discrepancy',
                        () => go(NavKey.discrepancy, const DiscrepancyScreen())),
                    _item(context, NavKey.products, Icons.inventory_2_outlined, 'Products',
                        () => go(NavKey.products, const ProductsScreen())),
                    _item(context, NavKey.deliveryPlan, Icons.local_shipping_outlined, 'Delivery Plan',
                        () => go(NavKey.deliveryPlan, const DeliveryPlansScreen())),
                    _item(context, NavKey.expenseHistory, Icons.receipt_long_outlined, 'Expense History',
                        () => go(NavKey.expenseHistory, const ExpensesScreen())),
                    _item(context, NavKey.deliveryHistory, Icons.history, 'Delivery History',
                        () => go(NavKey.deliveryHistory, const DeliveryHistoryScreen())),
                    _item(context, NavKey.subcategories, Icons.sell_outlined, 'Sub-categories',
                        () => go(NavKey.subcategories, const SubcategoryManagerScreen())),
                    _item(context, NavKey.staff, Icons.group_outlined, 'Staff',
                        () => go(NavKey.staff, const StaffListScreen())),
                    _item(context, NavKey.branches, Icons.store_mall_directory_outlined, 'Branches',
                        () => go(NavKey.branches, const BranchesScreen())),
                    const Divider(),
                    _section('EDITING TOOLS'),
                    _item(context, NavKey.confirmDelivery, Icons.check_circle_outline, 'Confirm Delivery',
                        () => go(NavKey.confirmDelivery, const DeliveryConfirmScreen())),
                    _item(context, NavKey.salesHistory, Icons.point_of_sale_outlined, 'Sales Entry History',
                        () => go(NavKey.salesHistory, const SalesHistoryScreen())),
                    _item(context, NavKey.openingStock, Icons.tune, 'Set Opening Stock',
                        () => go(NavKey.openingStock, const OpeningStockScreen())),
                    _item(context, NavKey.expenses, Icons.add_card_outlined, 'Add Expense',
                        () => go(NavKey.expenses, const ExpensesScreen(openAddOnStart: true))),
                  ] else ...[
                    _section('MENU'),
                    _item(context, NavKey.dashboard, Icons.dashboard_outlined, 'Dashboard',
                        () => go(NavKey.dashboard, const SizedBox())),
                    _item(context, NavKey.liveStock, Icons.warehouse_outlined, 'Live Stock',
                        () => go(NavKey.liveStock, const StockScreen())),
                    if (profile?.can('sales') ?? false) ...[
                      _item(context, NavKey.sales, Icons.point_of_sale_outlined, 'Sales Worksheet',
                          () => go(NavKey.sales, const SalesWorksheetScreen())),
                      _item(context, NavKey.cashCount, Icons.payments_outlined, 'Cash Count',
                          () => go(NavKey.cashCount, const CashCountScreen())),
                    ],
                    if (profile?.can('expenses') ?? false)
                      _item(context, NavKey.expenses, Icons.receipt_long_outlined, 'Expenses',
                          () => go(NavKey.expenses, const ExpensesScreen())),
                    if (profile?.can('delivery') ?? false)
                      _item(context, NavKey.confirmDelivery, Icons.local_shipping_outlined, 'Confirm Delivery',
                          () => go(NavKey.confirmDelivery, const DeliveryConfirmScreen())),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile?.email ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(isAdmin ? 'Admin' : 'Staff',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            SwitchListTile(
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              title: Text(isDark ? 'Dark Mode' : 'Light Mode'),
              value: isDark,
              onChanged: (v) => ref.read(themeModeProvider.notifier).toggle(v),
            ),
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () => go(NavKey.settings, const SettingsScreen()),
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () { Navigator.pop(context); authService.signOut(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold,
                color: Colors.grey, letterSpacing: 0.5)),
      );

  Widget _item(BuildContext context, NavKey key, IconData icon, String label, VoidCallback onTap) {
    final selected = key == current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected ? AppColors.brickRed : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 21,
                    color: selected ? Colors.white : AppColors.brickRed),
                const SizedBox(width: 14),
                Text(label,
                    style: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14.5,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}