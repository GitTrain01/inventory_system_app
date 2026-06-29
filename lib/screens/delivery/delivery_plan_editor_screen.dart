import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/conversion.dart';
import '../../models/product.dart';
import '../../services/delivery_service.dart';
import '../../state/active_branch_provider.dart';
import '../../state/catalog_providers.dart';
import '../../state/stock_providers.dart';
import '../../widgets/subcategory_filter.dart';

class DeliveryPlanEditorScreen extends ConsumerStatefulWidget {
  final DateTime date;
  const DeliveryPlanEditorScreen({super.key, required this.date});
  @override
  ConsumerState<DeliveryPlanEditorScreen> createState() => _EditorState();
}

class _EditorState extends ConsumerState<DeliveryPlanEditorScreen> {
  late DateTime _date;
  final _notes = TextEditingController();
  final Map<String, TextEditingController> _qty = {};
  String _filter = 'All';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);
  TextEditingController _ctrl(String id) => _qty.putIfAbsent(id, () => TextEditingController());

  @override
  void initState() {
    super.initState();
    _date = widget.date;
    _loadExisting();
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final c in _qty.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final branch = ref.read(activeBranchProvider);
    if (branch == null) { setState(() => _loading = false); return; }

    for (final c in _qty.values) {
      c.text = '';
    }
    _notes.text = '';

    final plan = await deliveryService.getPlanForDate(branch.id, _dateStr);
    if (plan != null) {
      _notes.text = plan.notes ?? '';
      final items = await deliveryService.getItems(plan.id);
      for (final it in items) {
        _ctrl(it.productId).text = _trim(it.plannedQty);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _trim(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2024), lastDate: DateTime(2030));
    if (picked != null) {
      setState(() => _date = picked);
      await _loadExisting();
    }
  }

  Future<void> _save(List<Product> products) async {
    final branch = ref.read(activeBranchProvider);
    if (branch == null) return;

    // Save iterates ALL products with a typed quantity, not the filtered view.
    final items = <({String productId, num plannedQty, num quantityInUnits})>[];
    for (final p in products) {
      final txt = _qty[p.id]?.text.trim() ?? '';
      if (txt.isEmpty) continue;
      final planned = num.tryParse(txt);
      if (planned == null || planned <= 0) continue;
      items.add((
        productId: p.id,
        plannedQty: planned,
        quantityInUnits: deliveryToBase(planned, p.deliveryConversion),
      ));
    }

    if (items.isEmpty) {
      setState(() => _error = 'Enter a planned quantity for at least one product.');
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      await deliveryService.savePlan(
        branchId: branch.id,
        planDate: _dateStr,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        items: items,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final stock = ref.watch(stockMapProvider).value ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Plan'),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(DateFormat('MMM d').format(_date)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (products) {
                final active = products.where((p) => p.isActive).toList();
                final subs = distinctSubcategories(active.map((p) => p.subcategory));
                final visible = active
                    .where((p) => matchesSubFilter(p.subcategory, _filter))
                    .toList();
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        controller: _notes,
                        decoration: const InputDecoration(labelText: 'Notes (optional)'),
                      ),
                    ),
                    SubcategoryFilterBar(
                      subcategories: subs,
                      selected: _filter,
                      onSelected: (s) => setState(() => _filter = s),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? const Center(child: Text('No products in this sub-category.'))
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              children: [
                                for (final p in visible)
                                  _ProductRow(
                                    product: p,
                                    controller: _ctrl(p.id),
                                    onHandPc: stock[p.id]?.quantity ?? 0,
                                    onChanged: () => setState(() {}),
                                  ),
                              ],
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
                          onPressed: _saving ? null : () => _save(active),
                          child: _saving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save plan'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final TextEditingController controller;
  final num onHandPc;
  final VoidCallback onChanged;
  const _ProductRow({
    required this.product,
    required this.controller,
    required this.onHandPc,
    required this.onChanged,
  });

  String _qtyStr(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  @override
  Widget build(BuildContext context) {
    final p = product;
    final deliveryUnit = (p.deliveryUnit != null && p.deliveryUnit!.isNotEmpty)
        ? p.deliveryUnit!
        : p.unit;

    String onHand;
    if (p.hasDeliveryUnit) {
      final s = splitDelivery(onHandPc, p.deliveryConversion);
      onHand =
          'On hand: ${s.deliveryWhole} ${p.deliveryUnit} + ${_qtyStr(s.baseRemainder)} ${p.unit}  (${_qtyStr(onHandPc)} ${p.unit})';
    } else {
      onHand = 'On hand: ${_qtyStr(onHandPc)} ${p.unit}';
    }

    final planned = num.tryParse(controller.text.trim());
    final preview = (planned != null && planned > 0)
        ? '= ${_qtyStr(deliveryToBase(planned, p.deliveryConversion))} ${p.unit}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(onHand, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 130,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Plan ($deliveryUnit)',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(preview, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}