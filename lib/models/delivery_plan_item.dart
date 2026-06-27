import '../core/parse.dart';

class DeliveryPlanItem {
  final String id;
  final String planId;
  final String productId;
  final String branchId;
  final num plannedQty;      // delivery units (kg / Pack)
  final num quantityInUnits; // base units (pc)

  const DeliveryPlanItem({
    required this.id,
    required this.planId,
    required this.productId,
    required this.branchId,
    required this.plannedQty,
    required this.quantityInUnits,
  });

  factory DeliveryPlanItem.fromJson(Map<String, dynamic> j) => DeliveryPlanItem(
        id: j['id'] as String,
        planId: j['plan_id'] as String,
        productId: j['product_id'] as String,
        branchId: j['branch_id'] as String,
        plannedQty: toNum(j['planned_qty']) ?? 0,
        quantityInUnits: toNum(j['quantity_in_units']) ?? 0,
      );
}