import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/dashboard_service.dart';
import '../../state/active_branch_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/dashboard_cards.dart';
import '../../widgets/stock_item_list.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});
  @override
  ConsumerState<AdminDashboard> createState() => _State();
}

class _State extends ConsumerState<AdminDashboard> {
  String _shift = 'day';
  bool _loading = true;
  StockSummary _stock = const StockSummary();
  CashSnapshot _cash = const CashSnapshot();
  String? _lastBranchId;

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _load() async {
    final branch = ref.read(activeBranchProvider);
    if (branch == null) { setState(() => _loading = false); return; }
    setState(() => _loading = true);
    final stock = await dashboardService.stockSummary(branch.id);
    final cash = await dashboardService.cashSnapshot(
        branchId: branch.id, date: _today, shift: _shift);
    if (mounted) setState(() { _stock = stock; _cash = cash; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final branch = ref.watch(activeBranchProvider);
    final nightMode = branch?.nightShiftEnabled ?? false;

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
                  const Text('Admin Dashboard',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  Text(DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            // was: if (_loading) Padding(...spinner...) else ...[ cards ]
            StockSummaryCard(s: _stock, showValue: true, loading: _loading),
            CashBreakdownCard(
              snap: _cash, nightMode: nightMode, shift: _shift,
              loading: _loading,
              onShiftChanged: (s) { setState(() => _shift = s); _load(); },
            ),
            const Divider(height: 24),
            const _SectionTile(title: 'Saleable Stock', consumable: false, showValue: true),
            const _SectionTile(title: 'Consumables', consumable: true, showValue: true),
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
  final bool showValue;
  const _SectionTile({required this.title, required this.consumable, required this.showValue});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      initiallyExpanded: !consumable, // saleable open, consumables collapsed
      childrenPadding: EdgeInsets.zero,
      children: [StockItemList(consumable: consumable, showValue: showValue)],
    );
  }
}