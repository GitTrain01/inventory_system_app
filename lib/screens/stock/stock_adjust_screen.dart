import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/conversion.dart';
import '../../core/formatters.dart';
import '../../models/product.dart';
import '../../services/stock_service.dart';
import '../../state/active_branch_provider.dart';
import '../../state/stock_providers.dart';

class StockAdjustScreen extends ConsumerStatefulWidget {
  final Product product;
  final num currentPc;
  const StockAdjustScreen({super.key, required this.product, required this.currentPc});

  @override
  ConsumerState<StockAdjustScreen> createState() => _StockAdjustScreenState();
}

class _StockAdjustScreenState extends ConsumerState<StockAdjustScreen> {
  late final TextEditingController _delivery; // whole delivery units (kg/pack)
  late final TextEditingController _base;      // leftover base units (pc)
  bool _saving = false;
  String? _error;

  bool get _dual => widget.product.hasDeliveryUnit;

  @override
  void initState() {
    super.initState();
    if (_dual) {
      final s = splitDelivery(widget.currentPc, widget.product.deliveryConversion);
      _delivery = TextEditingController(text: s.deliveryWhole.toString());
      _base = TextEditingController(text: qty(s.baseRemainder));
    } else {
      _delivery = TextEditingController(text: '0');
      _base = TextEditingController(text: qty(widget.currentPc));
    }
  }

  @override
  void dispose() {
    _delivery.dispose();
    _base.dispose();
    super.dispose();
  }

  num? get _totalPc {
    final d = num.tryParse(_delivery.text.trim());
    final b = num.tryParse(_base.text.trim());
    if (d == null || b == null) return null;
    return _dual ? deliveryToBase(d, widget.product.deliveryConversion) + b : b;
  }

  Future<void> _save() async {
    final branch = ref.read(activeBranchProvider);
    final total = _totalPc;
    if (branch == null) return;
    if (total == null || total < 0) {
      setState(() => _error = 'Enter valid, non-negative numbers.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await stockService.setQuantity(
          productId: widget.product.id, branchId: branch.id, quantity: total);
      ref.invalidate(stockMapProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final preview = _totalPc;
    return Scaffold(
      appBar: AppBar(title: Text('Count: ${p.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_dual) ...[
            Text('1 ${p.deliveryUnit} = ${qty(p.deliveryConversion)} ${p.unit}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _delivery,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: p.deliveryUnit),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _base,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: p.unit),
                  ),
                ),
              ],
            ),
          ] else
            TextField(
              controller: _base,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: 'Quantity (${p.unit})'),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total to save'),
                  Text(
                    preview == null ? '—' : '${qty(preview)} ${p.unit}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          if (preview != null) ...[
            const SizedBox(height: 8),
            Text('Value: ${peso.format(p.stockValue(preview))}',
                style: const TextStyle(color: Colors.grey)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save count'),
          ),
        ],
      ),
    );
  }
}