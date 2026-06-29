import '../core/supabase_client.dart';
import '../models/expense.dart';
import 'cash_service.dart';

class ExpensesService {
  Future<List<Expense>> listForShift(
      String branchId, String date, String shift) async {
    final rows = await supabase
        .from('expenses')
        .select()
        .eq('branch_id', branchId)
        .eq('expense_date', date)
        .eq('shift', shift)
        .order('created_at', ascending: false);
    return rows.map<Expense>((r) => Expense.fromJson(r)).toList();
  }

  Future<List<Expense>> listForDate(String branchId, String date) async {
    final rows = await supabase
        .from('expenses')
        .select()
        .eq('branch_id', branchId)
        .eq('expense_date', date)
        .order('created_at', ascending: false);
    return rows.map<Expense>((r) => Expense.fromJson(r)).toList();
  }

  Future<void> add({
    required String branchId,
    required String date,
    required String shift,
    required String item,
    String? description,
    required num value,
  }) async {
    final user = supabase.auth.currentUser;
    await supabase.from('expenses').insert({
      'branch_id': branchId,
      'expense_date': date,
      'shift': shift,
      'item': item,
      'description': description,
      'value': value,
      'submitted_by': user?.id,
      'submitted_by_email': user?.email,
    });
    // keep that shift's cash report in sync
    await cashService.recompute(branchId: branchId, date: date, shift: shift);
  }

  Future<void> delete({
    required String id,
    required String branchId,
    required String date,
    required String shift,
  }) async {
    await supabase.from('expenses').delete().eq('id', id);
    await cashService.recompute(branchId: branchId, date: date, shift: shift);
  }
  Future<void> edit({
    required String id,
    required String branchId,
    required String date,
    required String shift,
    required String item,
    String? description,
    required num value,
  }) async {
    await supabase.from('expenses').update({
      'item': item,
      'description': description,
      'value': value,
    }).eq('id', id);
    await cashService.recompute(branchId: branchId, date: date, shift: shift);
  }
}

final expensesService = ExpensesService();