import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/formatters.dart';
import '../../core/parse.dart';
import '../../models/product.dart';
import '../../services/delivery_service.dart';
import '../../services/products_service.dart';
import '../../state/active_branch_provider.dart';
import '../../widgets/subcategory_filter.dart';
import '../../widgets/skeleton_list.dart';
import 'delivery_record_editor.dart';

final _recordsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final b = ref.watch(activeBranchProvider);
  if (b == null) return const [];
  return deliveryService.listDeliveries(b.id);
});
final _historyProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final b = ref.watch(activeBranchProvider);
  if (b == null) return const [];
  return deliveryService.listHistory(b.id);
});
final _productsMapProvider = FutureProvider.autoDispose<Map<String, Product>>((ref) async {
  final b = ref.watch(activeBranchProvider);
  if (b == null) return const {};
  final list = await productsService.listForBranch(b.id);
  return {for (final p in list) p.id: p};
});

Map<String, List<Map<String, dynamic>>> _groupByDate(List<Map<String, dynamic>> rows) {
  final map = <String, List<Map<String, dynamic>>>{};
  for (final r in rows) {
    map.putIfAbsent(r['delivery_date'].toString(), () => []).add(r);
  }
  final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
  return {for (final k in keys) k: map[k]!};
}

class DeliveryHistoryScreen extends ConsumerStatefulWidget {
  const DeliveryHistoryScreen({super.key});
  @override
  ConsumerState<DeliveryHistoryScreen> createState() => _State();
}

class _State extends ConsumerState<DeliveryHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  String _filter = 'All';

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  String _subOf(Map<String, dynamic> r, Map<String, Product> products) {
    final p = products[r['product_id']];
    if (p != null) {
      return (p.subcategory?.trim().isNotEmpty ?? false) ? p.subcategory!.trim() : 'Uncategorized';
    }
    final name = (r['product_name'] ?? '') as String;
    for (final prod in products.values) {
      if (prod.name == name) {
        return (prod.subcategory?.trim().isNotEmpty ?? false) ? prod.subcategory!.trim() : 'Uncategorized';
      }
    }
    return 'Uncategorized';
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(_productsMapProvider).value ?? const {};
    final subs = distinctSubcategories(products.values.map((p) => p.subcategory));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery History'),
        bottom: TabBar(controller: _tab, tabs: const [Tab(text: 'Records'), Tab(text: 'Log')]),
      ),
      body: Column(
        children: [
          SubcategoryFilterBar(
            subcategories: subs,
            selected: _filter,
            onSelected: (s) => setState(() => _filter = s),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _RecordsTab(filter: _filter, subOf: _subOf),
                _LogTab(filter: _filter, subOf: _subOf),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsTab extends ConsumerWidget {
  final String filter;
  final String Function(Map<String, dynamic>, Map<String, Product>) subOf;
  const _RecordsTab({required this.filter, required this.subOf});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_recordsProvider);
    final products = ref.watch(_productsMapProvider).value ?? const {};
    final nightMode = ref.watch(activeBranchProvider)?.nightShiftEnabled ?? false;

    return async.when(
      loading: () => const SkeletonList(rows: 8),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allRows) {
        final rows = allRows
            .where((r) => matchesSubFilter(
                products[r['product_id']]?.subcategory, filter))
            .toList();
        if (rows.isEmpty) return const Center(child: Text('No delivery records.'));
        final grouped = _groupByDate(rows);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_recordsProvider),
          child: ListView(
            children: [
              for (final entry in grouped.entries)
                ExpansionTile(
                  title: Text(DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(entry.key)),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${entry.value.length} item${entry.value.length == 1 ? '' : 's'}'),
                  childrenPadding: EdgeInsets.zero,
                  children: entry.value.map((r) {
                    final p = products[r['product_id']];
                    final name = p?.name ?? 'Unknown';
                    final du = (p?.deliveryUnit?.isNotEmpty ?? false) ? p!.deliveryUnit! : (p?.unit ?? '');
                    final bu = p?.unit ?? 'pc';
                    final tag = nightMode ? (r['shift'] == 'night' ? '🌙 ' : '☀️ ') : '';
                    return ListTile(
                      dense: true,
                      title: Text('$tag$name'),
                      subtitle: Text('${qty(toNum(r['quantity_delivered']) ?? 0)} $du → '
                          '${qty(toNum(r['quantity_in_units']) ?? 0)} $bu'),
                      trailing: const Icon(Icons.edit_outlined, size: 18),
                      onTap: p == null ? null : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DeliveryRecordEditor(record: r, product: p)),
                      ).then((_) {
                        ref.invalidate(_recordsProvider);
                        ref.invalidate(_historyProvider);
                      }),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LogTab extends ConsumerWidget {
  final String filter;
  final String Function(Map<String, dynamic>, Map<String, Product>) subOf;
  const _LogTab({required this.filter, required this.subOf});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_historyProvider);
    final products = ref.watch(_productsMapProvider).value ?? const {};
    final nightMode = ref.watch(activeBranchProvider)?.nightShiftEnabled ?? false;

    Color actionColor(String a) => a == 'created'
        ? Colors.green : (a == 'edited' ? Colors.orange : Colors.red);

    return async.when(
      loading: () => const SkeletonList(rows: 8),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allRows) {
        final rows = allRows.where((r) {
          if (filter == 'All') return true;
          return subOf(r, products) == filter;
        }).toList();
        if (rows.isEmpty) return const Center(child: Text('No history yet.'));
        final grouped = _groupByDate(rows);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_historyProvider),
          child: ListView(
            children: [
              for (final entry in grouped.entries)
                ExpansionTile(
                  title: Text(DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(entry.key)),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${entry.value.length} entr${entry.value.length == 1 ? 'y' : 'ies'}'),
                  childrenPadding: EdgeInsets.zero,
                  children: entry.value.map((r) {
                    final action = (r['action'] ?? '') as String;
                    final tag = nightMode ? (r['shift'] == 'night' ? '🌙 ' : '☀️ ') : '';
                    return ListTile(
                      dense: true,
                      leading: Chip(
                        label: Text(action, style: const TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: actionColor(action),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      title: Text('$tag${r['product_name'] ?? ''}'),
                      subtitle: Text('${qty(toNum(r['quantity_in_units']) ?? 0)} units • '
                          '${r['performed_by_email'] ?? ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete log entry?'),
                              content: const Text('Removes this audit row only. No stock change.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await deliveryService.deleteHistoryEntry(r['id'] as String);
                            ref.invalidate(_historyProvider);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}