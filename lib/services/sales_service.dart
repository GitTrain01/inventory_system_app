import 'package:intl/intl.dart';
import '../core/parse.dart';
import '../core/supabase_client.dart';
import '../models/worksheet_line.dart';
import 'products_service.dart';
import 'stock_service.dart';
import 'logic/sales_math.dart';

class SalesSubmission {
  final String productId;
  final num opening, delivered, closing, sold, value;
  final bool consumableChecked;
  const SalesSubmission({
    required this.productId,
    required this.opening,
    required this.delivered,
    required this.closing,
    required this.sold,
    required this.value,
    required this.consumableChecked,
  });
}

class SalesService {
  /// Builds the worksheet for (branch, date, shift).
  Future<List<WorksheetLine>> getWorksheet({
    required String branchId,
    required String date, // yyyy-MM-dd
    required String shift,
  }) async {
    final products =
        await productsService.listForBranch(branchId, activeOnly: true);

    final saleRows = await supabase
        .from('end_of_day_sale')
        .select()
        .eq('branch_id', branchId)
        .eq('sale_date', date)
        .eq('shift', shift);
    final existing = {for (final r in saleRows) r['product_id'] as String: r};

    final delRows = await supabase
        .from('delivery')
        .select('product_id, quantity_in_units')
        .eq('branch_id', branchId)
        .eq('delivery_date', date)
        .eq('shift', shift);
    final deliveredBy = <String, num>{};
    for (final r in delRows) {
      final pid = r['product_id'] as String;
      deliveredBy[pid] = (deliveredBy[pid] ?? 0) + (toNum(r['quantity_in_units']) ?? 0);
    }

    final stock = await stockService.mapForBranch(branchId);

    final lines = <WorksheetLine>[];
    for (final p in products) {
      final delivered = deliveredBy[p.id] ?? 0;
      final saved = existing[p.id];

      num opening;
      if (saved != null && saved['opening_stock'] != null) {
        opening = toNum(saved['opening_stock']) ?? 0; // explicit saved row wins
      } else {
        // auto: live stock minus this shift's deliveries (don't double-count)
        final live = stock[p.id]?.quantity ?? 0;
        opening = live - delivered;
        if (opening < 0) opening = 0;
      }

      lines.add(WorksheetLine(
        product: p,
        opening: opening,
        delivered: delivered,
        existingClosing: saved == null ? null : toNum(saved['closing_stock']),
        existingLow: saved == null ? false : (saved['consumable_checked'] ?? false) as bool,
      ));
    }
    return lines;
  }

  /// Upserts each counted line and writes its closing back to live_stock.
  Future<void> submitSales({
    required String branchId,
    required String date,
    required String shift,
    required List<SalesSubmission> subs,
  }) async {
    final user = supabase.auth.currentUser;
    for (final s in subs) {
      await supabase.from('end_of_day_sale').upsert({
        'product_id': s.productId,
        'branch_id': branchId,
        'sale_date': date,
        'shift': shift,
        'opening_stock': s.opening,
        'delivered_qty': s.delivered,
        'closing_stock': s.closing,
        'consumable_checked': s.consumableChecked,
        'units_sold': s.sold,
        'expected_value': s.value,
        'submitted_by': user?.id,
        'submitted_by_email': user?.email,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'product_id,sale_date,shift');

      await stockService.setQuantity(
        productId: s.productId, branchId: branchId, quantity: s.closing);
    }
  }

  String today() => DateFormat('yyyy-MM-dd').format(DateTime.now());
}

final salesService = SalesService();