import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/dashboard_service.dart';
import '../../state/active_branch_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/dashboard_cards.dart';
import '../../widgets/stock_item_list.dart';

class StaffDashboard extends ConsumerStatefulWidget {
  const StaffDashboard({super.key});
  @override
  ConsumerState<StaffDashboard> createState() => _State();
}

class _State extends ConsumerState<StaffDashboard> {
  bool _loading = true;
  StockSummary _stock = const StockSummary();
  String? _lastBranchId;

  Future<void> _load() async {
    final branch = ref.read(activeBranchProvider);
    if (branch == null) { setState(() => _loading = false); return; }
    setState(() => _loading = true);
    final stock = await dashboardService.stockSummary(branch.id);
    if (mounted) setState(() { _stock = stock; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final branch = ref.watch(activeBranchProvider);

    if (branch != null && branch.id != _lastBranchId) {
      _lastBranchId = branch.id;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    return Scaffold(
      drawer: const AppDrawer(current: NavKey.dashboard),
      appBar: AppBar(
        centerTitle: true,
        title: Text('4C SnackHouse ${branch?.name ?? ''}',
            style: const TextStyle(
                color: AppColors.brickRed, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Staff Dashboard',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  Text(DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            StockSummaryCard(s: _stock, showValue: false, loading: _loading),
            const Divider(height: 24),
            const _SectionTile(title: 'Saleable Items', consumable: false),
            const _SectionTile(title: 'Consumable Items', consumable: true),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final String title;
  final bool consumable;
  const _SectionTile({required this.title, required this.consumable});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      initiallyExpanded: !consumable,
      childrenPadding: EdgeInsets.zero,
      children: [StockItemList(consumable: consumable, showValue: false)],
    );
  }
}