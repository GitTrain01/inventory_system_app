import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/formatters.dart';
import '../../core/pay_week.dart';
import '../../services/reports_service.dart';
import '../../state/active_branch_provider.dart';
import '../../widgets/skeleton_list.dart';
import '../../widgets/animated_list_item.dart';
import 'sales_editor_screen.dart';

final discrepancyProvider =
    FutureProvider.autoDispose<List<ShiftReport>>((ref) async {
  final branch = ref.watch(activeBranchProvider);
  if (branch == null) return const [];
  return reportsService.listReports(branch.id);
});

class DiscrepancyScreen extends ConsumerWidget {
  const DiscrepancyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(discrepancyProvider);
    final nightMode = ref.watch(activeBranchProvider)?.nightShiftEnabled ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Discrepancy Review')),
      body: async.when(
        loading: () => const SkeletonList(rows: 10),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(child: Text('No submitted shifts yet.'));
          }
          final groups = <String, List<ShiftReport>>{};
          for (final r in reports) {
            groups.putIfAbsent(payWeekKey(r.date), () => []).add(r);
          }
          var idx = 0;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(discrepancyProvider),
            child: ListView(
              children: [
                for (final entry in groups.entries) ...[
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(payWeekLabel(entry.value.first.date),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...entry.value.map((r) =>
                      AnimatedListItem(index: idx++, child: _row(context, ref, r, nightMode))),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, ShiftReport r, bool nightMode) {
    final tag = nightMode ? (r.shift == 'night' ? '🌙 ' : '☀️ ') : '';
    final status = r.discrepancy == 0
        ? 'BALANCED'
        : (r.discrepancy < 0 ? 'SHORT' : 'OVER');
    final color = r.discrepancy == 0
        ? Colors.green
        : (r.discrepancy < 0 ? Colors.red : Colors.blue);

    return ListTile(
      title: Text('$tag${DateFormat('EEE, MMM d, yyyy').format(r.date)}'),
      subtitle: Text('Sales ${peso.format(r.sales)} • '
          'Cash ${peso.format(r.cash + r.coins)} • Exp ${peso.format(r.expenses)}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(peso.format(r.discrepancy),
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text(status, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SalesEditorScreen(date: r.date, shift: r.shift),
        ),
      ).then((_) => ref.invalidate(discrepancyProvider)),
    );
  }
}