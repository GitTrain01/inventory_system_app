import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../models/product.dart';
import '../../services/products_service.dart';
import '../../state/catalog_providers.dart';
import 'product_form.dart';
import 'subcategory_manager_screen.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Sub-categories',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubcategoryManagerScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductForm()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products yet. Tap “Add product”.'));
          }
          final grouped = _group(products);
          final cats = grouped.keys.toList()..sort(_cmp);
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final cat in cats) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(cat,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                for (final sub in (grouped[cat]!.keys.toList()..sort(_cmp))) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(sub,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: Colors.grey)),
                  ),
                  ...grouped[cat]![sub]!
                      .map((p) => _ProductTile(product: p, ref: ref)),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Map<String, Map<String, List<Product>>> _group(List<Product> items) {
    final out = <String, Map<String, List<Product>>>{};
    for (final p in items) {
      final cat = (p.category?.trim().isNotEmpty ?? false)
          ? p.category!.trim()
          : 'Uncategorized';
      final sub = (p.subcategory?.trim().isNotEmpty ?? false)
          ? p.subcategory!.trim()
          : 'Uncategorized';
      out.putIfAbsent(cat, () => {}).putIfAbsent(sub, () => []).add(p);
    }
    return out;
  }

  int _cmp(String a, String b) {
    if (a == 'Uncategorized') return 1;
    if (b == 'Uncategorized') return -1;
    return a.compareTo(b);
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final WidgetRef ref;
  const _ProductTile({required this.product, required this.ref});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final conv = (p.deliveryUnit != null && p.deliveryUnit!.isNotEmpty)
        ? ' • 1 ${p.deliveryUnit} = ${qty(p.deliveryConversion)} ${p.unit}'
        : '';
    return ListTile(
      enabled: p.isActive,
      title: Text(p.name),
      subtitle: Text('${p.unit}$conv • ${peso.format(p.pricePerUnit)}'),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'edit') {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => ProductForm(product: p)));
          } else if (v == 'toggle') {
            await productsService.setActive(p.id, !p.isActive);
            ref.invalidate(productsProvider);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(
              value: 'toggle',
              child: Text(p.isActive ? 'Deactivate' : 'Activate')),
        ],
      ),
    );
  }
}