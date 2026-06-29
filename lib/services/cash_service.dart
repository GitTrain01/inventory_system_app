import '../core/parse.dart';
import '../core/supabase_client.dart';
import 'logic/sales_math.dart';

class CashService {
  /// Sum of sold value for (branch, date, shift) from submitted sales.
  Future<num> salesTotal(String branchId, String date, String shift) async {
    final rows = await supabase
        .from('end_of_day_sale')
        .select('expected_value')
        .eq('branch_id', branchId).eq('sale_date', date).eq('shift', shift);
    num t = 0;
    for (final r in rows) {
      t += toNum(r['expected_value']) ?? 0;
    }
    return t;
  }

  /// Sum of expenses for (branch, date, shift).
  Future<num> expensesTotal(String branchId, String date, String shift) async {
    final rows = await supabase
        .from('expenses')
        .select('value')
        .eq('branch_id', branchId).eq('expense_date', date).eq('shift', shift);
    num t = 0;
    for (final r in rows) {
      t += toNum(r['value']) ?? 0;
    }
    return t;
  }

  /// The current cash report row, if any.
  Future<Map<String, dynamic>?> getReport(
      String branchId, String date, String shift) async {
    return supabase
        .from('daily_cash_report')
        .select()
        .eq('branch_id', branchId).eq('report_date', date).eq('shift', shift)
        .maybeSingle();
  }

  /// Shared recompute: refresh sales+expenses+discrepancy on the report,
  /// preserving counted cash/coins. Called by cash submit AND by Phase 9
  /// after an expense changes. Creates the row if missing (unlocked).
  Future<void> recompute({
    required String branchId,
    required String date,
    required String shift,
  }) async {
    final existing = await getReport(branchId, date, shift);
    final cash = toNum(existing?['counted_bills']) ?? 0;
    final coins = toNum(existing?['counted_coins']) ?? 0;

    final sales = await salesTotal(branchId, date, shift);
    final expenses = await expensesTotal(branchId, date, shift);
    final disc = computeDiscrepancy(
        cash: cash, coins: coins, expenses: expenses, sales: sales);

    await supabase.from('daily_cash_report').upsert({
      'branch_id': branchId,
      'report_date': date,
      'shift': shift,
      'counted_bills': cash,
      'counted_coins': coins,
      'counted_cash': cash + coins,
      'sales_total': sales,
      'expected_total': sales,
      'expenses_total': expenses,
      'discrepancy': disc,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'branch_id,report_date,shift');
  }

  /// Submit the counted bills + coins and lock the report.
  Future<void> submitCashCount({
    required String branchId,
    required String date,
    required String shift,
    required num bills,
    required num coins,
  }) async {
    final user = supabase.auth.currentUser;
    final sales = await salesTotal(branchId, date, shift);
    final expenses = await expensesTotal(branchId, date, shift);
    final disc = computeDiscrepancy(
        cash: bills, coins: coins, expenses: expenses, sales: sales);

    await supabase.from('daily_cash_report').upsert({
      'branch_id': branchId,
      'report_date': date,
      'shift': shift,
      'counted_bills': bills,
      'counted_coins': coins,
      'counted_cash': bills + coins,
      'sales_total': sales,
      'expected_total': sales,
      'expenses_total': expenses,
      'discrepancy': disc,
      'is_locked': true,
      'submitted_by': user?.id,
      'submitted_by_email': user?.email,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'branch_id,report_date,shift');
  }
  /// Admin: reopen a locked report so it can be corrected.
  Future<void> setLocked({
    required String branchId,
    required String date,
    required String shift,
    required bool locked,
  }) async {
    await supabase.from('daily_cash_report').update({
      'is_locked': locked,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('branch_id', branchId).eq('report_date', date).eq('shift', shift);
  }
}

final cashService = CashService();