import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../core/formatters.dart';
import '../services/dashboard_service.dart';

class StockSummaryCard extends StatelessWidget {
  final StockSummary s;
  final bool showValue;
  final bool loading;
  const StockSummaryCard({
    super.key, required this.s, required this.showValue, this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: loading,
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Live Stock',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _group(context, 'Saleable', s.saleableCount, s.saleableQty, s.saleableValue),
              const Divider(height: 20),
              _group(context, 'Consumable', s.consumableCount, s.consumableQty, s.consumableValue),
              if (showValue) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total stock value', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(peso.format(s.totalValue),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _group(BuildContext context, String label, int count, num qtyVal, num value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('$count item${count == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${qty(qtyVal)} units', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (showValue)
              Text(peso.format(value), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

class CashBreakdownCard extends StatelessWidget {
  final CashSnapshot snap;
  final bool nightMode;
  final String shift;
  final ValueChanged<String> onShiftChanged;
  final bool loading;
  const CashBreakdownCard({
    super.key, required this.snap, required this.nightMode,
    required this.shift, required this.onShiftChanged, this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final d = snap.discrepancy;
    final status = !snap.hasCashReport
        ? 'NO CASH COUNT'
        : (d == 0 ? 'BALANCED' : (d < 0 ? 'SHORT' : 'OVER'));
    final color = !snap.hasCashReport
        ? Colors.grey
        : (d == 0 ? Colors.green : (d < 0 ? Colors.red : Colors.blue));

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cash Breakdown',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (nightMode)
                  SegmentedButton<String>(
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    segments: const [
                      ButtonSegment(value: 'day', label: Text('☀️')),
                      ButtonSegment(value: 'night', label: Text('🌙')),
                    ],
                    selected: {shift},
                    onSelectionChanged: (s) => onShiftChanged(s.first),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Skeletonizer(
              enabled: loading,
              child: Column(
                children: [
                  _line('Bills', peso.format(snap.bills)),
                  _line('Coins', peso.format(snap.coins)),
                  _line('Expenses', peso.format(snap.expenses)),
                  _line('Reconciled', peso.format(snap.countedCash + snap.expenses)),
                  const Divider(),
                  _line('Sales (expected)', peso.format(snap.sales)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                      if (snap.hasCashReport)
                        Text(peso.format(d),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value)],
        ),
      );
}