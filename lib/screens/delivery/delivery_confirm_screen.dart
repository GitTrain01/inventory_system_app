import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/formatters.dart';
import '../../models/delivery_plan.dart';
import '../../models/delivery_plan_item.dart';
import '../../models/product.dart';
import '../../services/delivery_service.dart';
import '../../services/products_service.dart';
import '../../state/active_branch_provider.dart';
import '../../state/delivery_providers.dart';
import '../../state/stock_providers.dart';

class DeliveryConfirmScreen extends ConsumerStatefulWidget {
  const DeliveryConfirmScreen({super.key});
  @override
  ConsumerState<DeliveryConfirmScreen> createState() => _State();
}

class _State extends ConsumerState<DeliveryConfirmScreen> {
  String? _branchId;
  DateTime _date = DateTime.now();
  String _shift = 'day';
  bool _loading = false;
  bool _confirming = false;
  String? _error;
  DeliveryPlan? _plan;
  List<DeliveryPlanItem> _items = [];
  Map<String, Product> _productsById = {};

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  String _branchName() {
    final branches = ref.read(branchesProvider).value ?? const [];
    for (final b in branches) {
      if (b.id == _branchId) return b.name;
    }
    return 'this branch';
  }

  Future<void> _load() async {
    if (_branchId == null) return;
    setState(() { _loading = true; _error = null; _plan = null; _items = []; });
    try {
      final plan = await deliveryService.getPlanForDate(_branchId!, _dateStr);
      var items = <DeliveryPlanItem>[];
      var map = <String, Product>{};
      if (plan != null) {
        items = await deliveryService.getItems(plan.id);
        final products = await productsService.listForBranch(_branchId!);
        map = {for (final p in products) p.id: p};
      }
      setState(() { _plan = plan; _items = items; _productsById = map; });
    } catch (e) {
      setState(() => _error = 'Load failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2024), lastDate: DateTime(2030));
    if (picked != null) { setState(() => _date = picked); await _load(); }
  }

  Future<void> _confirm() async {
    final plan = _plan;
    if (plan == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm delivery?'),
        content: Text(
            'Adds the planned quantities to ${_branchName()} stock and marks the plan delivered.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() { _confirming = true; _error = null; });
    try {
      await deliveryService.confirmDelivery(
          plan: plan, items: _items, productsById: _productsById, shift: _shift);
      ref.invalidate(stockMapProvider);
      ref.invalidate(deliveryPlansProvider);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delivery confirmed — stock updated.')));
      }
    } catch (e) {
      setState(() => _error = 'Confirm failed: $e');
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchesProvider).value ?? const [];
    final delivered = _plan?.status == 'delivered';

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Delivery')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _branchId,
                  decoration: const InputDecoration(labelText: 'Branch (any)'),
                  items: branches
                      .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                      .toList(),
                  onChanged: (v) { setState(() => _branchId = v); _load(); },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(DateFormat('EEE, MMM d').format(_date)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'day', label: Text('Day')),
                        ButtonSegment(value: 'night', label: Text('Night')),
                      ],
                      selected: {_shift},
                      onSelectionChanged: (s) => setState(() => _shift = s.first),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _body(delivered)),
        ],
      ),
    );
  }

  Widget _body(bool delivered) {
    if (_branchId == null) {
      return const Center(child: Text('Pick a branch to load its plan.'));
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, style: const TextStyle(color: Colors.red))));
    }
    if (_plan == null) {
      return Center(child: Text(
          'No plan for ${_branchName()} on ${DateFormat('MMM d').format(_date)}.'));
    }
    return Column(
      children: [
        if (delivered)
          Container(
            width: double.infinity,
            color: Colors.green.shade100,
            padding: const EdgeInsets.all(12),
            child: const Text('✓ Already delivered', textAlign: TextAlign.center),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final it = _items[i];
              final p = _productsById[it.productId];
              final name = p?.name ?? 'Unknown product';
              final du = (p?.deliveryUnit?.isNotEmpty ?? false)
                  ? p!.deliveryUnit! : (p?.unit ?? 'units');
              final bu = p?.unit ?? 'pc';
              return ListTile(
                title: Text(name),
                subtitle: Text('${qty(it.plannedQty)} $du  →  ${qty(it.quantityInUnits)} $bu'),
              );
            },
          ),
        ),
        if (!delivered)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _confirming || _items.isEmpty ? null : _confirm,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_confirming
                    ? 'Confirming…'
                    : 'Confirm → add to ${_branchName()} stock'),
              ),
            ),
          ),
      ],
    );
  }
}