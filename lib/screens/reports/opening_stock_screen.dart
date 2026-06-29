import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/formatters.dart';
import '../../models/product.dart';
import '../../services/sales_service.dart';
import '../../services/products_service.dart';
import '../../state/active_branch_provider.dart';
import '../../widgets/subcategory_filter.dart';

class OpeningStockScreen extends ConsumerStatefulWidget {
  const OpeningStockScreen({super.key});
  @override
  ConsumerState<OpeningStockScreen> createState() => _State();
}

class _State extends ConsumerState<OpeningStockScreen> {
  DateTime _date = DateTime.now();
  String _shift = 'day';
  String _filter = 'All';
  bool _loading = true;
  List<Product> _products = [];
  final Map<String, TextEditingController> _ctrl = {};

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);
  TextEditingController _c(String id) => _ctrl.putIfAbsent(id, () => TextEditingController());

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { for (final c in _ctrl.values) { c.dispose(); } super.dispose(); }

  Future<void> _load() async {
    final b = ref.read(activeBranchProvider);
    if (b == null) { setState(() => _loading = false); return; }
    setState(() => _loading = true);
    final products = await productsService.listForBranch(b.id, activeOnly: true);
    final saleable = products.where((p) => p.category != 'Consumable').toList();
    setState(() { _products = saleable; _loading = false; });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date, firstDate: DateTime(2024), lastDate: DateTime(2030));
    if (picked != null) { setState(() => _date = picked); }
  }

  Future<void> _save() async {
    final b = ref.read(activeBranchProvider);
    if (b == null) return;
    int saved = 0;
    for (final p in _products) {
      final txt = _ctrl[p.id]?.text.trim() ?? '';
      if (txt.isEmpty) continue;
      final v = num.tryParse(txt);
      if (v == null) continue;
      await salesService.setOpening(
          productId: p.id, branchId: b.id, date: _dateStr, shift: _shift, opening: v);
      saved++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Set opening for $saved product(s).')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nightMode = ref.watch(activeBranchProvider)?.nightShiftEnabled ?? false;
    final subs = distinctSubcategories(_products.map((p) => p.subcategory));
    final filtered = _products.where((p) => matchesSubFilter(p.subcategory, _filter)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Opening Stock'),
        actions: [
          TextButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(DateFormat('MMM d').format(_date))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (nightMode)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'day', label: Text('☀️ Day')),
                        ButtonSegment(value: 'night', label: Text('🌙 Night')),
                      ],
                      selected: {_shift},
                      onSelectionChanged: (s) => setState(() => _shift = s.first),
                    ),
                  ),
                SubcategoryFilterBar(subcategories: subs, selected: _filter,
                    onSelected: (s) => setState(() => _filter = s)),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Overrides the auto-filled opening for this date/shift. Leave blank to keep auto.',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return ListTile(
                        title: Text(p.name),
                        trailing: SizedBox(
                          width: 110,
                          child: TextField(
                            controller: _c(p.id),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(isDense: true, labelText: p.unit, border: const OutlineInputBorder()),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(onPressed: _save, child: const Text('Save opening overrides')),
                  ),
                ),
              ],
            ),
    );
  }
}