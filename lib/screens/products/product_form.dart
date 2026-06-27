import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../services/products_service.dart';
import '../../state/active_branch_provider.dart';
import '../../state/catalog_providers.dart';

class ProductForm extends ConsumerStatefulWidget {
  final Product? product; // null = create
  const ProductForm({super.key, this.product});

  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _deliveryUnit;
  late final TextEditingController _conversion;
  late final TextEditingController _price;
  String? _subcategory;
  String? _category;
  bool _active = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
  
    _unit = TextEditingController(text: p?.unit ?? '');
    _deliveryUnit = TextEditingController(text: p?.deliveryUnit ?? '');
    _conversion =
        TextEditingController(text: p == null ? '' : qtyText(p.deliveryConversion));
    _price = TextEditingController(text: p == null ? '' : p.pricePerUnit.toString());
    _subcategory = p?.subcategory;
    const cats = ['Saleable', 'Consumable'];
_category = p == null ? 'Saleable' : (cats.contains(p.category) ? p.category : null);
    _active = p?.isActive ?? true;
  }

  String qtyText(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  @override
  void dispose() {
    for (final c in [_name, _unit, _deliveryUnit, _conversion, _price]) {
  c.dispose();
}
    super.dispose();
  }

  Future<void> _save() async {
  final branch = ref.read(activeBranchProvider);
  if (branch == null) return;

  final name = _name.text.trim();
  final unit = _unit.text.trim();
  final price = num.tryParse(_price.text.trim());

  final deliveryUnitText = _deliveryUnit.text.trim();
  final hasDeliveryUnit = deliveryUnitText.isNotEmpty;

  // Conversion only matters when there's a delivery unit; otherwise it's 1.
  final num? conv = hasDeliveryUnit ? num.tryParse(_conversion.text.trim()) : 1;

  // Name exactly what's missing so the message is never misleading.
  final missing = <String>[];
  if (name.isEmpty) missing.add('name');
  if (_category == null) missing.add('category');
  if (unit.isEmpty) missing.add('unit');
  if (price == null) missing.add('a numeric price');
  if (hasDeliveryUnit && (conv == null || conv <= 0)) {
    missing.add('a numeric conversion (a delivery unit is set)');
  }
  if (missing.isNotEmpty) {
    setState(() => _error = 'Missing or invalid: ${missing.join(', ')}.');
    return;
  }

  setState(() { _saving = true; _error = null; });
  try {
    final category = _category;
    if (_isEdit) {
      await productsService.update(
        widget.product!.id,
        name: name, category: category, subcategory: _subcategory,
        unit: unit,
        deliveryUnit: hasDeliveryUnit ? deliveryUnitText : null,
        deliveryConversion: conv!, pricePerUnit: price!, isActive: _active,
      );
    } else {
      await productsService.create(
        branchId: branch.id,
        name: name, category: category, subcategory: _subcategory,
        unit: unit,
        deliveryUnit: hasDeliveryUnit ? deliveryUnitText : null,
        deliveryConversion: conv!, pricePerUnit: price!, isActive: _active,
      );
    }
    ref.invalidate(productsProvider);
    if (mounted) Navigator.pop(context);
  } catch (e) {
    setState(() => _error = 'Save failed: $e');
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final subsAsync = ref.watch(subcategoriesProvider);
    final subNames = <String>{
      'Uncategorized',
      ...subsAsync.value?.map((s) => s.name) ?? const <String>[],
      if (_subcategory != null) _subcategory!,
    }.toList();

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit product' : 'Add product')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
        initialValue: const ['saleable', 'consumable'].contains(_category) ? _category : null,
        decoration: const InputDecoration(labelText: 'Category'),
        items: const [
          DropdownMenuItem(value: 'saleable', child: Text('saleable')),
          DropdownMenuItem(value: 'consumable', child: Text('consumable')),
        ],
        onChanged: (v) => setState(() => _category = v),
),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: subNames.contains(_subcategory) ? _subcategory : null,
            decoration: const InputDecoration(labelText: 'Sub-category'),
            items: subNames
                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                .toList(),
            onChanged: (v) => setState(() => _subcategory = v),
          ),
          const SizedBox(height: 12),
          TextField(controller: _unit, decoration: const InputDecoration(labelText: 'Unit (e.g. pc)')),
          const SizedBox(height: 12),
          TextField(controller: _deliveryUnit, decoration: const InputDecoration(labelText: 'Delivery unit (e.g. kg)')),
          const SizedBox(height: 12),
          TextField(
            controller: _conversion,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Delivery conversion', helperText: '1 delivery unit = this many base units'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Price per unit'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Active'),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}