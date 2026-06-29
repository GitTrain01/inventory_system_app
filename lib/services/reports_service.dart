import '../core/parse.dart';
import '../core/supabase_client.dart';

/// One reconciled (date, shift) entry for admin review.
class ShiftReport {
  final DateTime date;
  final String shift;
  final num sales;
  final num cash;
  final num coins;
  final num expenses;
  final num discrepancy;
  final bool hasCashReport;

  const ShiftReport({
    required this.date,
    required this.shift,
    required this.sales,
    required this.cash,
    required this.coins,
    required this.expenses,
    required this.discrepancy,
    required this.hasCashReport,
  });

  String get dateStr =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class ReportsService {
  /// All cash reports for a branch, newest first, as ShiftReports.
  Future<List<ShiftReport>> listReports(String branchId) async {
    final rows = await supabase
        .from('daily_cash_report')
        .select()
        .eq('branch_id', branchId)
        .order('report_date', ascending: false)
        .order('shift');

    return rows.map<ShiftReport>((r) {
      return ShiftReport(
        date: DateTime.parse(r['report_date'].toString()),
        shift: (r['shift'] ?? 'day') as String,
        sales: toNum(r['sales_total']) ?? 0,
        cash: toNum(r['counted_bills']) ?? 0,
        coins: toNum(r['counted_coins']) ?? 0,
        expenses: toNum(r['expenses_total']) ?? 0,
        discrepancy: toNum(r['discrepancy']) ?? 0,
        hasCashReport: true,
      );
    }).toList();
  }
}

final reportsService = ReportsService();