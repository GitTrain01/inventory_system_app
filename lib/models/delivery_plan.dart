class DeliveryPlan {
  final String id;
  final String branchId;
  final DateTime planDate;
  final String status;
  final String? notes;
  final String? createdByEmail;

  const DeliveryPlan({
    required this.id,
    required this.branchId,
    required this.planDate,
    required this.status,
    this.notes,
    this.createdByEmail,
  });

  factory DeliveryPlan.fromJson(Map<String, dynamic> j) => DeliveryPlan(
        id: j['id'] as String,
        branchId: j['branch_id'] as String,
        planDate: DateTime.parse(j['plan_date'].toString()),
        status: (j['status'] ?? 'in_progress') as String,
        notes: j['notes'] as String?,
        createdByEmail: j['created_by_email'] as String?,
      );
}