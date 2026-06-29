import '../core/parse.dart';
import '../core/supabase_client.dart';
import '../models/product.dart';
import 'products_service.dart';
import 'stock_service.dart';

/// Aggregated stock figures for a branch (shift-independent).
class StockSummary {
  final int saleableCount;
  final num saleableQty;
  final num saleableValue;
  final int consumableCount;
  final num consumableQty;
  final num consumableValue;

  const StockSummary({
    this.saleableCount = 0, this.saleableQty = 0, this.saleableValue = 0,
    this.consumableCount = 0, this.consumableQty = 0, this.consumableValue = 0,
  });

  num get totalValue => saleableValue + consumableValue;
}

/// Money snapshot for one (branch, date, shift).
class CashSnapshot {
  final num sales, bills, coins, expenses, discrepancy;
  final bool hasCashReport;
  const CashSnapshot({
    this.sales = 0, this.bills = 0, this.coins = 0,
    this.expenses = 0, this.discrepancy = 0, this.hasCashReport = false,
  });
  num get countedCash => bills + coins;
}

class DashboardService {
  Future<StockSummary> stockSummary(String branchId) async {
    final products = await productsService.listForBranch(branchId, activeOnly: true);
    final stock = await stockService.mapForBranch(branchId);

    int sc = 0, cc = 0;
    num sq = 0, sv = 0, cq = 0, cv = 0;
    for (final Product p in products) {
      final qty = stock[p.id]?.quantity ?? 0;
      final value = qty * p.pricePerUnit;
      if (p.category == 'Consumable') {
        cc++; cq += qty; cv += value;
      } else {
        sc++; sq += qty; sv += value;
      }
    }
    return StockSummary(
      saleableCount: sc, saleableQty: sq, saleableValue: sv,
      consumableCount: cc, consumableQty: cq, consumableValue: cv,
    );
  }

  Future<CashSnapshot> cashSnapshot({
    required String branchId, required String date, required String shift,
  }) async {
    final saleRows = await supabase
        .from('end_of_day_sale')
        .select('expected_value')
        .eq('branch_id', branchId).eq('sale_date', date).eq('shift', shift);
    num sales = 0;
    for (final r in saleRows) { sales += toNum(r['expected_value']) ?? 0; }

    final cash = await supabase
        .from('daily_cash_report')
        .select()
        .eq('branch_id', branchId).eq('report_date', date).eq('shift', shift)
        .maybeSingle();

    if (cash == null) {
      return CashSnapshot(sales: sales, hasCashReport: false);
    }
    return CashSnapshot(
      sales: toNum(cash['sales_total']) ?? sales,
      bills: toNum(cash['counted_bills']) ?? 0,
      coins: toNum(cash['counted_coins']) ?? 0,
      expenses: toNum(cash['expenses_total']) ?? 0,
      discrepancy: toNum(cash['discrepancy']) ?? 0,
      hasCashReport: true,
    );
  }
}

final dashboardService = DashboardService();