import '../core/parse.dart';

class StockLevel {
  final String productId;
  final String branchId;
  final num quantity; // base units (pc)
  final DateTime? updatedDate;

  const StockLevel({
    required this.productId,
    required this.branchId,
    this.quantity = 0,
    this.updatedDate,
  });

  factory StockLevel.fromJson(Map<String, dynamic> j) => StockLevel(
        productId: j['product_id'] as String,
        branchId: j['branch_id'] as String,
        quantity: toNum(j['quantity']) ?? 0,
        updatedDate: j['updated_date'] == null
            ? null
            : DateTime.tryParse(j['updated_date'].toString()),
      );
}