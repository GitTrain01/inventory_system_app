import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/conversion.dart';
import '../../core/formatters.dart';
import '../../core/parse.dart';
import '../../core/supabase_client.dart';
import '../../models/product.dart';
import '../../services/cash_service.dart';
import '../../services/products_service.dart';
import '../../services/stock_service.dart';
import '../../services/logic/sales_math.dart';
import '../../state/active_branch_provider.dart';


/// Admin editor for one (date, shift): adjust each saleable's closing and
/// the counted cash/coins, then recompute ONLY this entry's discrepancy.
class SalesEditorScreen extends ConsumerStatefulWidget {
  final DateTime date;
  final String shift;
  const SalesEditorScreen({super.key, required this.date, required this.shift});

  @override
  ConsumerState<SalesEditorScreen> createState() => _State();
}

class _SaleRow {
  final Product product;
  final num opening;
  final num delivered;
  final TextEditingController closing;
  _SaleRow(this.product, this.opening, this.delivered, this.closing);
  num get available => opening + delivered;
}

class _State extends ConsumerState<SalesEditorScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final List<_SaleRow> _rows = [];
  final _bills = TextEditingController();
  final _coins = TextEditingController();

  String get _dateStr => DateFormat('yyyy-MM-dd').format(widget.date);

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    for (final r in _rows) { r.closing.dispose(); }
    _bills.dispose();
    _coins.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final branch = ref.read(activeBranchProvider);
    if (branch == null) { setState(() => _loading = false); return; }
    setState(() => _loading = true);

    final saleRows = await supabase
        .from('end_of_day_sale')
        .select()
        .eq('branch_id', branch.id)
        .eq('sale_date', _dateStr)
        .eq('shift', widget.shift);
    final products = await productsService.listForBranch(branch.id);
    final byId = {for (final p in products) p.id: p};

    _rows.clear();
    for (final r in saleRows) {
      final p = byId[r['product_id'] as String];
      if (p == null || p.category == 'Consumable') continue; // edit saleables
      final opening = toNum(r['opening_stock']) ?? 0;
      final delivered = toNum(r['delivered_qty']) ?? 0;
      final closing = toNum(r['closing_stock']) ?? 0;
      _rows.add(_SaleRow(p, opening, delivered,
          TextEditingController(text: qty(closing))));
    }

    final cash = await cashService.getReport(branch.id, _dateStr, widget.shift);
    _bills.text = cash?['counted_bills'] == null ? '' : qty(toNum(cash!['counted_bills'])!);
    _coins.text = cash?['counted_coins'] == null ? '' : qty(toNum(cash!['counted_coins'])!);

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final branch = ref.read(activeBranchProvider);
    if (branch == null) return;
    setState(() { _saving = true; _error = null; });
    try {
      final user = supabase.auth.currentUser;

      // 1. Update each saleable's closing + recomputed sold/value; sync live_stock.
      for (final r in _rows) {
        final closing = num.tryParse(r.closing.text.trim());
        if (closing == null) continue;
        if (closing < 0 || closing > r.available) {
          setState(() => _error =
              '${r.product.name}: closing must be 0–${qty(r.available)}.');
          setState(() => _saving = false);
          return;
        }
        final sold = computeSold(
            opening: r.opening, delivered: r.delivered, closing: closing);
        await supabase.from('end_of_day_sale').update({
          'closing_stock': closing,
          'units_sold': sold,
          'expected_value': computeValue(sold: sold, pricePerUnit: r.product.pricePerUnit),
          'submitted_by': user?.id,
          'submitted_by_email': user?.email,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('product_id', r.product.id)
          .eq('sale_date', _dateStr)
          .eq('shift', widget.shift);

        await stockService.setQuantity(
            productId: r.product.id, branchId: branch.id, quantity: closing);
      }

      // 2. Persist edited cash/coins (preserve lock).
      await supabase.from('daily_cash_report').upsert({
        'branch_id': branch.id,
        'report_date': _dateStr,
        'shift': widget.shift,
        'counted_bills': num.tryParse(_bills.text.trim()) ?? 0,
        'counted_coins': num.tryParse(_coins.text.trim()) ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'branch_id,report_date,shift');

      // 3. Recompute ONLY this (date, shift)'s discrepancy.
      await cashService.recompute(
          branchId: branch.id, date: _dateStr, shift: widget.shift);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry updated and recomputed.')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  late Future<bool> _lockFuture = _loadLock();

  Future<bool> _loadLock() async {
    final branch = ref.read(activeBranchProvider);
    if (branch == null) return false;
    final r = await cashService.getReport(branch.id, _dateStr, widget.shift);
    return (r?['is_locked'] ?? false) as bool;
  }

  @override
  Widget build(BuildContext context) {
    final nightMode = ref.watch(activeBranchProvider)?.nightShiftEnabled ?? false;
    final tag = nightMode ? (widget.shift == 'night' ? '🌙 Night' : '☀️ Day') : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Entry'),
        actions: [
          FutureBuilder(
            future: _lockFuture,
            builder: (context, snap) {
              final locked = snap.data ?? false;
              return IconButton(
                tooltip: locked ? 'Unlock (reopen)' : 'Lock',
                icon: Icon(locked ? Icons.lock : Icons.lock_open),
                onPressed: () async {
                  final branch = ref.read(activeBranchProvider);
                  if (branch == null) return;
                  await cashService.setLocked(
                    branchId: branch.id, date: _dateStr,
                    shift: widget.shift, locked: !locked);
                  setState(() => _lockFuture = _loadLock());
                },
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Saleable closing counts',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_rows.isEmpty)
                  const Text('No saleable entries for this shift.',
                      style: TextStyle(color: Colors.grey)),
                ..._rows.map(_saleTile),
                const Divider(height: 32),
                const Text('Counted cash',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _bills,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Cash (bills) ₱', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _coins,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Coins ₱', border: OutlineInputBorder()),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save & recompute this shift'),
                ),
              ],
            ),
    );
  }

  Widget _saleTile(_SaleRow r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('Available ${qty(r.available)} ${r.product.unit}  '
              '(open ${qty(r.opening)} + del ${qty(r.delivered)})',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          SizedBox(
            width: 160,
            child: TextField(
              controller: r.closing,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Closing (${r.product.unit})',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}