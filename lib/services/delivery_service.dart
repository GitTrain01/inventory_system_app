import '../core/supabase_client.dart';
import '../models/delivery_plan.dart';
import '../models/delivery_plan_item.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import 'stock_service.dart';

class DeliveryService {
  Future<List<DeliveryPlan>> listPlans(String branchId) async {
    final rows = await supabase
        .from('delivery_plan')
        .select()
        .eq('branch_id', branchId)
        .order('plan_date', ascending: false);
    return rows.map<DeliveryPlan>((r) => DeliveryPlan.fromJson(r)).toList();
  }

  Future<DeliveryPlan?> getPlanForDate(String branchId, String planDate) async {
    final row = await supabase
        .from('delivery_plan')
        .select()
        .eq('branch_id', branchId)
        .eq('plan_date', planDate)
        .maybeSingle();
    return row == null ? null : DeliveryPlan.fromJson(row);
  }

  Future<List<DeliveryPlanItem>> getItems(String planId) async {
    final rows = await supabase
        .from('delivery_plan_item')
        .select()
        .eq('plan_id', planId);
    return rows.map<DeliveryPlanItem>((r) => DeliveryPlanItem.fromJson(r)).toList();
  }

  /// Confirm a whole plan: per item insert delivery (trigger stamps branch_id),
/// bump live_stock, log history; then mark the plan delivered.
Future<void> confirmDelivery({
  required DeliveryPlan plan,
  required List<DeliveryPlanItem> items,
  required Map<String, Product> productsById,
  required String shift,
}) async {
  final user = supabase.auth.currentUser;
  final dateStr = DateFormat('yyyy-MM-dd').format(plan.planDate);

  for (final it in items) {
    final product = productsById[it.productId];

    // 1. delivery row — branch_id intentionally omitted (trigger sets it).
    await supabase.from('delivery').insert({
      'product_id': it.productId,
      'delivery_date': dateStr,
      'shift': shift,
      'quantity_delivered': it.plannedQty,
      'quantity_in_units': it.quantityInUnits,
      'submitted_by': user?.id,
      'submitted_by_email': user?.email,
    });

    // 2. raise live stock by the converted base units.
    await stockService.increment(
      productId: it.productId,
      branchId: it.branchId,
      delta: it.quantityInUnits,
    );

    // 3. audit trail.
    await supabase.from('delivery_history').insert({
      'branch_id': it.branchId,
      'product_name': product?.name ?? 'Unknown product',
      'delivery_date': dateStr,
      'shift': shift,
      'quantity_delivered': it.plannedQty,
      'quantity_in_units': it.quantityInUnits,
      'action': 'created',
      'performed_by': user?.id,
      'performed_by_email': user?.email,
    });
  }

  // 4. flip the plan.
  await supabase.from('delivery_plan').update({
    'status': 'delivered',
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', plan.id);
}

  /// Create-or-update the (branch, date) plan, then replace its items.
  Future<void> savePlan({
    required String branchId,
    required String planDate,
    String? notes,
    required List<({String productId, num plannedQty, num quantityInUnits})> items,
  }) async {
    final user = supabase.auth.currentUser;

    final existing = await getPlanForDate(branchId, planDate);
    String planId;
    if (existing == null) {
      final inserted = await supabase.from('delivery_plan').insert({
        'branch_id': branchId,
        'plan_date': planDate,
        'status': 'draft',
        'notes': notes,
        'created_by': user?.id,
        'created_by_email': user?.email,
      }).select('id').single();
      planId = inserted['id'] as String;
    } else {
      planId = existing.id;
      await supabase.from('delivery_plan').update({
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', planId);
    }

    // Replace items wholesale (plans are small; simplest correct approach).
    await supabase.from('delivery_plan_item').delete().eq('plan_id', planId);
    if (items.isNotEmpty) {
      await supabase.from('delivery_plan_item').insert([
        for (final it in items)
          {
            'plan_id': planId,
            'product_id': it.productId,
            'branch_id': branchId,
            'planned_qty': it.plannedQty,
            'quantity_in_units': it.quantityInUnits,
          }
      ]);
    }
  }
}

final deliveryService = DeliveryService();