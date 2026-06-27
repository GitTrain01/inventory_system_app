import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/conversion.dart';
import '../../core/formatters.dart';
import '../../models/product.dart';
import '../../state/catalog_providers.dart';
import '../../state/stock_providers.dart';
import 'stock_adjust_screen.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final stockAsync = ref.watch(stockMapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Stock')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          final active = products.where((p) => p.isActive).toList();
          if (active.isEmpty) {
            return const Center(child: Text('No active products.'));
          }
          final stock = stockAsync.value ?? const {};
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(stockMapProvider);
              ref.invalidate(productsProvider);
            },
            child: ListView.separated(
              itemCount: active.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = active[i];
                final qtyPc = stock[p.id]?.quantity ?? 0;
                return _StockTile(product: p, qtyPc: qtyPc);
              },
            ),
          );
        },
      ),
    );
  }
}

class _StockTile extends ConsumerWidget {
  final Product product;
  final num qtyPc;
  const _StockTile({required this.product, required this.qtyPc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      trailing: Text(peso.format(p.stockValue(qtyPc)),
          style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => StockAdjustScreen(product: p, currentPc: qtyPc)),
      ),
    );
  }
}