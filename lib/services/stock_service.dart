import '../core/parse.dart';
import '../core/supabase_client.dart';
import '../models/live_stock.dart';

class StockService {
  Future<Map<String, StockLevel>> mapForBranch(String branchId) async {
    final rows =
        await supabase.from('live_stock').select().eq('branch_id', branchId);
    final out = <String, StockLevel>{};
    for (final r in rows) {
      final s = StockLevel.fromJson(r);
      out[s.productId] = s;
    }
    return out;
  }

  Future<void> setQuantity({
    required String productId,
    required String branchId,
    required num quantity,
  }) async {
    await supabase.from('live_stock').upsert({
      'product_id': productId,
      'branch_id': branchId,
      'quantity': quantity,
      'updated_date': DateTime.now().toIso8601String(),
    }, onConflict: 'product_id,branch_id');
  }

  /// Add to (or subtract from) the current quantity. Creates the row if missing.
  /// Add to (or subtract from) the current quantity. Creates the row if missing.
  /// Floored at 0 so a downward correction can't go negative.
    Future<void> increment({
      required String productId,
      required String branchId,
      required num delta,
    }) async {
      final existing = await supabase
          .from('live_stock')
          .select('quantity')
          .eq('product_id', productId)
          .eq('branch_id', branchId)
          .maybeSingle();
      final current = existing == null ? 0 : (toNum(existing['quantity']) ?? 0);
      final next = current + delta;
      await setQuantity(
          productId: productId, branchId: branchId,
          quantity: next < 0 ? 0 : next);
    }
  }

final stockService = StockService();