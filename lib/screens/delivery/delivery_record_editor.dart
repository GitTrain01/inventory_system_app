import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/conversion.dart';
import '../../core/formatters.dart';
import '../../core/parse.dart';
import '../../models/product.dart';
import '../../services/delivery_service.dart';
import '../../state/active_branch_provider.dart';
import '../../state/stock_providers.dart';

class DeliveryRecordEditor extends ConsumerStatefulWidget {
  final Map<String, dynamic> record;
  final Product product;
  const DeliveryRecordEditor({super.key, required this.record, required this.product});
  @override
  ConsumerState<DeliveryRecordEditor> createState() => _State();
}

class _State extends ConsumerState<DeliveryRecordEditor> {
  late final TextEditingController _qty;
  bool _saving = false;
  String? _error;

  num get _oldUnits => toNum(widget.record['quantity_in_units']) ?? 0;
  String get _date => widget.record['delivery_date'].toString();
  String get _shift => (widget.record['shift'] ?? 'day') as String;

  @override
  void initState() {
    super.initState();
    _qty = TextEditingController(text: qty(toNum(widget.record['quantity_delivered']) ?? 0));
  }

  @override
  void dispose() { _qty.dispose(); super.dispose(); }

  Future<void> _save() async {
    final branch = ref.read(activeBranchProvider);
    final newPlanned = num.tryParse(_qty.text.trim());
    if (branch == null) return;
    if (newPlanned == null || newPlanned < 0) {
      setState(() => _error = 'Enter a valid quantity.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await deliveryService.editDelivery(
        deliveryId: widget.record['id'] as String,
        productId: widget.product.id,
        branchId: branch.id,
        productName: widget.product.name,
        date: _date, shift: _shift,
        newPlannedQty: newPlanned,
        conversion: widget.product.deliveryConversion,
        oldQuantityInUnits: _oldUnits,
      );
      ref.invalidate(stockMapProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final branch = ref.read(activeBranchProvider);
    if (branch == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete delivery record?'),
        content: const Text(
            'Removes the record and logs it. Note: the stock that was added '
            'will NOT be reversed (the physical stock stays).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await deliveryService.deleteDelivery(
        deliveryId: widget.record['id'] as String,
        branchId: branch.id,
        productName: widget.product.name,
        date: _date, shift: _shift,
        quantityDelivered: toNum(widget.record['quantity_delivered']) ?? 0,
        quantityInUnits: _oldUnits,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _error = 'Delete failed: $e'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final du = (p.deliveryUnit?.isNotEmpty ?? false) ? p.deliveryUnit! : p.unit;
    final newPlanned = num.tryParse(_qty.text.trim());
    final newUnits = newPlanned == null ? null : deliveryToBase(newPlanned, p.deliveryConversion);
    final diff = newUnits == null ? null : newUnits - _oldUnits;

    return Scaffold(
      appBar: AppBar(title: Text('Edit: ${p.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(_date))} • '
              '${_shift == 'night' ? '🌙 Night' : '☀️ Day'}',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: 'Delivered ($du)', border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          if (newUnits != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _line('New total', '${qty(newUnits)} ${p.unit}'),
                    _line('Old total', '${qty(_oldUnits)} ${p.unit}'),
                    const Divider(),
                    _line('Stock adjustment',
                        '${diff! >= 0 ? '+' : ''}${qty(diff)} ${p.unit}'),
                  ],
                ),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save & adjust stock'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saving ? null : _delete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Delete record', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _line(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Text(v)]),
      );
}