import '../core/parse.dart';

class Expense {
  final String id;
  final String branchId;
  final DateTime expenseDate;
  final String shift;
  final String item;
  final String? description;
  final num value;
  final String? submittedByEmail;

  const Expense({
    required this.id,
    required this.branchId,
    required this.expenseDate,
    required this.shift,
    required this.item,
    this.description,
    this.value = 0,
    this.submittedByEmail,
  });

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        branchId: j['branch_id'] as String,
        expenseDate: DateTime.parse(j['expense_date'].toString()),
        shift: (j['shift'] ?? 'day') as String,
        item: (j['item'] ?? '') as String,
        description: j['description'] as String?,
        value: toNum(j['value']) ?? 0,
        submittedByEmail: j['submitted_by_email'] as String?,
      );
}