import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/supabase_client.dart';
import '../../state/active_branch_provider.dart';
import '../../widgets/animated_list_item.dart';
import 'sales_editor_screen.dart';

class _Entry {
  final DateTime date;
  final String shift;
  final int productCount;
  final bool locked;
  final bool hasCashReport;
  _Entry(this.date, this.shift, this.productCount, this.locked, this.hasCashReport);
}

final salesHistoryProvider =
    FutureProvider.autoDispose<List<_Entry>>((ref) async {
  final branch = ref.watch(activeBranchProvider);
  if (branch == null) return const [];

  final sales = await supabase
      .from('end_of_day_sale')
      .select('sale_date, shift, product_id')
      .eq('branch_id', branch.id);

  final cash = await supabase
      .from('daily_cash_report')
      .select('report_date, shift, is_locked')
      .eq('branch_id', branch.id);

  final lockMap = <String, bool>{};
  for (final c in cash) {
    lockMap['${c['report_date']}_${c['shift']}'] = (c['is_locked'] ?? false) as bool;
  }

  final grouped = <String, int>{};
  for (final s in sales) {
    grouped.update('${s['sale_date']}_${s['shift']}', (v) => v + 1, ifAbsent: () => 1);
  }

  final entries = grouped.entries.map((e) {
    final parts = e.key.split('_');
    final date = DateTime.parse(parts[0]);
    final shift = parts[1];
    return _Entry(date, shift, e.value, lockMap[e.key] ?? false, lockMap.containsKey(e.key));
  }).toList()
    ..sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : a.shift.compareTo(b.shift);
    });
  return entries;
});

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(salesHistoryProvider);
    final nightMode = ref.watch(activeBranchProvider)?.nightShiftEnabled ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Sales Entry History')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return _empty();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(salesHistoryProvider),
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = entries[i];
                final tag = nightMode ? (e.shift == 'night' ? '🌙 ' : '☀️ ') : '';
                return AnimatedListItem(
                  index: i,
                  child: ListTile(
                    leading: Icon(e.locked ? Icons.lock_outline : Icons.lock_open_outlined,
                        color: e.locked ? Colors.amber.shade700 : Colors.grey, size: 20),
                    title: Text('$tag${DateFormat('EEE, MMM d, yyyy').format(e.date)}'),
                    subtitle: Text('${e.productCount} product${e.productCount == 1 ? '' : 's'}'
                        '${e.locked ? ' • locked' : ''}'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SalesEditorScreen(date: e.date, shift: e.shift)),
                    ).then((_) => ref.invalidate(salesHistoryProvider)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _empty() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 56, color: Colors.grey),
              SizedBox(height: 16),
              Text('No sales entries yet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('Once staff submit end-of-day sales, each day appears here for review and corrections.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
}