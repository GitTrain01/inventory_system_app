import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/conversion.dart';
import '../core/formatters.dart';
import '../models/product.dart';
import '../state/catalog_providers.dart';
import '../state/stock_providers.dart';
import 'subcategory_filter.dart';

/// Filterable saleable/consumable stock list. [showValue] gates peso for staff.
class StockItemList extends ConsumerStatefulWidget {
  final bool consumable; // false = saleable
  final bool showValue;
  const StockItemList({super.key, required this.consumable, required this.showValue});
  @override
  ConsumerState<StockItemList> createState() => _State();
}

class _State extends ConsumerState<StockItemList> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final stock = ref.watch(stockMapProvider).value ?? const {};

    return productsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e')),
      data: (products) {
        final items = products
            .where((p) => p.isActive)
            .where((p) => widget.consumable
                ? p.category == 'Consumable'
                : p.category != 'Consumable')
            .toList();
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No items.', style: TextStyle(color: Colors.grey)));
        }
        final subs = distinctSubcategories(items.map((p) => p.subcategory));
        final visible = items.where((p) => matchesSubFilter(p.subcategory, _filter)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SubcategoryFilterBar(
              subcategories: subs,
              selected: _filter,
              onSelected: (s) => setState(() => _filter = s),
            ),
            ...visible.map((p) => _tile(context, p, stock[p.id]?.quantity ?? 0)),
          ],
        );
      },
    );
  }

  Widget _tile(BuildContext context, Product p, num qtyPc) {
    String breakdown = '${qty(qtyPc)} ${p.unit}';
    if (p.hasDeliveryUnit) {
      final s = splitDelivery(qtyPc, p.deliveryConversion);
      breakdown = '${s.deliveryWhole} ${p.deliveryUnit} + ${qty(s.baseRemainder)} ${p.unit}';
    }
    return ListTile(
      dense: true,
      title: Text(p.name),
      subtitle: Text(breakdown),
      trailing: widget.showValue
          ? Text(peso.format(p.stockValue(qtyPc)),
              style: const TextStyle(fontWeight: FontWeight.w600))
          : null,
    );
  }
}