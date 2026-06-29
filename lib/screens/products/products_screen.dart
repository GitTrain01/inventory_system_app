import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../models/product.dart';
import '../../services/products_service.dart';
import '../../state/catalog_providers.dart';
import '../../widgets/subcategory_filter.dart';
import '../../widgets/animated_list_item.dart';
import 'product_form.dart';
import 'subcategory_manager_screen.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});
  @override
  ConsumerState<ProductsScreen> createState() => _State();
}

class _State extends ConsumerState<ProductsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
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
        ).then((_) => ref.invalidate(productsProvider)),
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
          final subs = distinctSubcategories(products.map((p) => p.subcategory));
          final visible = products
              .where((p) => matchesSubFilter(p.subcategory, _filter))
              .toList();

          return Column(
            children: [
              SubcategoryFilterBar(
                subcategories: subs,
                selected: _filter,
                onSelected: (s) => setState(() => _filter = s),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const Center(child: Text('No products in this sub-category.'))
                    : _grouped(context, visible),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _grouped(BuildContext context, List<Product> products) {
    final grouped = _group(products);
    final cats = grouped.keys.toList()..sort(_cmp);
    var idx = 0; // running index for stagger across groups
    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        for (final cat in cats) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(cat, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final sub in (grouped[cat]!.keys.toList()..sort(_cmp))) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(sub,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey)),
            ),
            ...grouped[cat]![sub]!.map((p) =>
                AnimatedListItem(index: idx++, child: _ProductTile(product: p, ref: ref))),
          ],
        ],
      ],
    );
  }

  Map<String, Map<String, List<Product>>> _group(List<Product> items) {
    final out = <String, Map<String, List<Product>>>{};
    for (final p in items) {
      final cat = (p.category?.trim().isNotEmpty ?? false) ? p.category!.trim() : 'Uncategorized';
      final sub = (p.subcategory?.trim().isNotEmpty ?? false) ? p.subcategory!.trim() : 'Uncategorized';
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
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProductForm(product: p)))
                .then((_) => ref.invalidate(productsProvider));
          } else if (v == 'toggle') {
            await productsService.setActive(p.id, !p.isActive);
            ref.invalidate(productsProvider);
          } else if (v == 'delete') {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Delete “${p.name}”?'),
                content: const Text(
                    'This permanently removes the product and its stock/history rows. '
                    'To just hide it, use Deactivate instead.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                ],
              ),
            );
            if (ok == true) {
              await productsService.delete(p.id);
              ref.invalidate(productsProvider);
            }
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'toggle', child: Text(p.isActive ? 'Deactivate' : 'Activate')),
          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}