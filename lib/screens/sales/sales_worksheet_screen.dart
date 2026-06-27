import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/conversion.dart';
import '../../core/formatters.dart';
import '../../models/product.dart';
import '../../models/worksheet_line.dart';
import '../../services/sales_service.dart';
import '../../services/logic/sales_math.dart';
import '../../state/active_branch_provider.dart';
import '../../state/profile_provider.dart';
import '../../state/stock_providers.dart';

class SalesWorksheetScreen extends ConsumerStatefulWidget {
  const SalesWorksheetScreen({super.key});
  @override
  ConsumerState<SalesWorksheetScreen> createState() => _State();
}

class _State extends ConsumerState<SalesWorksheetScreen> {
  DateTime _date = DateTime.now();
  String _shift = 'day';
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<WorksheetLine> _lines = [];

  final Map<String, TextEditingController> _deliv = {}; // pack/kg box
  final Map<String, TextEditingController> _base = {};   // pc box
  final Map<String, bool> _low = {};

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);
  TextEditingController _dCtrl(String id) => _deliv.putIfAbsent(id, () => TextEditingController());
  TextEditingController _bCtrl(String id) => _base.putIfAbsent(id, () => TextEditingController());

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [..._deliv.values, ..._base.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final branch = ref.read(activeBranchProvider);
    if (branch == null) { setState(() => _loading = false); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final lines = await salesService.getWorksheet(
          branchId: branch.id, date: _dateStr, shift: _shift);
      for (final l in lines) {
        final pid = l.product.id;
        _low[pid] = l.existingLow;
        if (l.existingClosing != null) {
          if (l.product.hasDeliveryUnit) {
            final s = splitDelivery(l.existingClosing!, l.product.deliveryConversion);
            _dCtrl(pid).text = s.deliveryWhole.toString();
            _bCtrl(pid).text = qty(s.baseRemainder);
          } else {
            _bCtrl(pid).text = qty(l.existingClosing!);
          }
        } else {
          _dCtrl(pid).text = '';
          _bCtrl(pid).text = '';
        }
      }
      setState(() => _lines = lines);
    } catch (e) {
      setState(() => _error = 'Load failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Closing in base units for a product, or null if not counted.
  num? _closing(Product p) {
    final bTxt = _bCtrl(p.id).text.trim();
    if (p.hasDeliveryUnit) {
      final dTxt = _dCtrl(p.id).text.trim();
      if (dTxt.isEmpty && bTxt.isEmpty) return null;
      final d = num.tryParse(dTxt.isEmpty ? '0' : dTxt);
      final b = num.tryParse(bTxt.isEmpty ? '0' : bTxt);
      if (d == null || b == null) return null;
      return deliveryToBase(d, p.deliveryConversion) + b;
    } else {
      if (bTxt.isEmpty) return null;
      return num.tryParse(bTxt);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2024), lastDate: DateTime(2030));
    if (picked != null) { setState(() => _date = picked); await _load(); }
  }

  Future<void> _submit() async {
    final branch = ref.read(activeBranchProvider);
    if (branch == null) return;

    final subs = <SalesSubmission>[];
    for (final l in _lines) {
      final closing = _closing(l.product);
      if (closing == null) continue; // skip uncounted
      if (closing < 0) {
        setState(() => _error = '${l.product.name}: closing can’t be negative.');
        return;
      }
      if (!l.isConsumable && closing > l.available) {
        setState(() => _error =
            '${l.product.name}: closing (${qty(closing)}) exceeds available (${qty(l.available)}).');
        return;
      }
      if (l.isConsumable) {
        subs.add(SalesSubmission(
          productId: l.product.id, opening: l.opening, delivered: l.delivered,
          closing: closing, sold: 0, value: 0, consumableChecked: _low[l.product.id] ?? false));
      } else {
        final sold = computeSold(opening: l.opening, delivered: l.delivered, closing: closing);
        subs.add(SalesSubmission(
          productId: l.product.id, opening: l.opening, delivered: l.delivered,
          closing: closing, sold: sold,
          value: computeValue(sold: sold, pricePerUnit: l.product.pricePerUnit),
          consumableChecked: false));
      }
    }
    if (subs.isEmpty) {
      setState(() => _error = 'Enter a closing count for at least one product.');
      return;
    }

    setState(() { _submitting = true; _error = null; });
    try {
      await salesService.submitSales(
          branchId: branch.id, date: _dateStr, shift: _shift, subs: subs);
      ref.invalidate(stockMapProvider);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sales submitted — stock updated.')));
      }
    } catch (e) {
      setState(() => _error = 'Submit failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(profileProvider).value?.isAdmin ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Worksheet'),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(DateFormat('MMM d').format(_date)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'day', label: Text('Day')),
                ButtonSegment(value: 'night', label: Text('Night')),
              ],
              selected: {_shift},
              onSelectionChanged: (s) { setState(() => _shift = s.first); _load(); },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _lines.isEmpty
                    ? const Center(child: Text('No active products.'))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: _lines.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _row(_lines[i], isAdmin),
                      ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _submitting || _loading ? null : _submit,
                child: Text(_submitting ? 'Submitting…' : 'Submit sales'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(WorksheetLine l, bool isAdmin) {
    final p = l.product;
    final dual = p.hasDeliveryUnit;
    final closing = _closing(p);

    final closingBoxes = Row(
      children: [
        if (dual) ...[
          SizedBox(
            width: 90,
            child: TextField(
              controller: _dCtrl(p.id),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(isDense: true, labelText: p.deliveryUnit, border: const OutlineInputBorder()),
            ),
          ),
          const SizedBox(width: 8),
        ],
        SizedBox(
          width: 90,
          child: TextField(
            controller: _bCtrl(p.id),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(isDense: true, labelText: p.unit, border: const OutlineInputBorder()),
          ),
        ),
      ],
    );

    if (l.isConsumable) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Text('Consumable — count remaining', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                closingBoxes,
                const Spacer(),
                Row(children: [
                  Checkbox(
                    value: _low[p.id] ?? false,
                    onChanged: (v) => setState(() => _low[p.id] = v ?? false),
                  ),
                  const Text('Low'),
                ]),
              ],
            ),
            if (closing != null)
              Text('Total: ${qty(closing)} ${p.unit}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    // saleable
    final sold = (closing != null && closing <= l.available)
        ? computeSold(opening: l.opening, delivered: l.delivered, closing: closing)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            'Opening ${qty(l.opening)} + Delivered ${qty(l.delivered)} = Available ${qty(l.available)} ${p.unit}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Closing: '),
              closingBoxes,
              const Spacer(),
              if (isAdmin && sold != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Sold ${qty(sold)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(peso.format(computeValue(sold: sold, pricePerUnit: p.pricePerUnit)),
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
            ],
          ),
          if (closing != null && closing > l.available)
            Text('Closing exceeds available', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
        ],
      ),
    );
  }
}