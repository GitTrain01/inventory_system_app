import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/conversion.dart';
import '../../core/formatters.dart';
import '../../models/product.dart';
import '../../state/catalog_providers.dart';
import '../../state/profile_provider.dart';
import '../../state/stock_providers.dart';
import '../../widgets/subcategory_filter.dart';
import '../../widgets/skeleton_list.dart';
import '../../widgets/animated_list_item.dart';
import 'stock_adjust_screen.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});
  @override
  ConsumerState<StockScreen> createState() => _State();
}

class _State extends ConsumerState<StockScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final stockAsync = ref.watch(stockMapProvider);
    final isAdmin = ref.watch(profileProvider).value?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Live Stock')),
      body: productsAsync.when(
        loading: () => SkeletonList(hasTrailing: isAdmin),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          final active = products.where((p) => p.isActive).toList();
          if (active.isEmpty) {
            return const Center(child: Text('No active products.'));
          }
          final subs = distinctSubcategories(active.map((p) => p.subcategory));
          final filtered =
              active.where((p) => matchesSubFilter(p.subcategory, _filter)).toList();
          final stock = stockAsync.value ?? const {};

          return Column(
            children: [
              SubcategoryFilterBar(
                subcategories: subs,
                selected: _filter,
                onSelected: (s) => setState(() => _filter = s),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(stockMapProvider);
                    ref.invalidate(productsProvider);
                  },
                  child: filtered.isEmpty
                      ? ListView(children: const [
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('No products in this sub-category.')),
                          )
                        ])
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final p = filtered[i];
                            final qtyPc = stock[p.id]?.quantity ?? 0;
                            return AnimatedListItem(
                              index: i,
                              child: _StockTile(
                                  product: p, qtyPc: qtyPc, isAdmin: isAdmin),
                            );
                          },
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

class _StockTile extends StatelessWidget {
  final Product product;
  final num qtyPc;
  final bool isAdmin;
  const _StockTile({required this.product, required this.qtyPc, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final p = product;
    String breakdown = '${qty(qtyPc)} ${p.unit}';
    if (p.hasDeliveryUnit) {
      final s = splitDelivery(qtyPc, p.deliveryConversion);
      breakdown =
          '${s.deliveryWhole} ${p.deliveryUnit} + ${qty(s.baseRemainder)} ${p.unit}  (${qty(qtyPc)} ${p.unit})';
    }
    return ListTile(
      title: Text(p.name),
      subtitle: Text(breakdown),
      trailing: isAdmin
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(peso.format(p.stockValue(qtyPc)),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18),
              ],
            )
          : null,
      onTap: isAdmin
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => StockAdjustScreen(product: p, currentPc: qtyPc)),
              )
          : null,
    );
  }
}