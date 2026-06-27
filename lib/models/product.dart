import '../core/parse.dart';

class Product {
  final String id;
  final String branchId;
  final String name;
  final String? category;
  final String? subcategory;
  final String unit;
  final String? deliveryUnit;
  final num deliveryConversion;
  final num pricePerUnit;
  final bool isActive;

  const Product({
    required this.id,
    required this.branchId,
    required this.name,
    this.category,
    this.subcategory,
    required this.unit,
    this.deliveryUnit,
    this.deliveryConversion = 1,
    this.pricePerUnit = 0,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        branchId: j['branch_id'] as String,
        name: j['name'] as String,
        category: j['category'] as String?,
        subcategory: j['subcategory'] as String?,
        unit: (j['unit'] ?? '') as String,
        deliveryUnit: j['delivery_unit'] as String?,
        deliveryConversion: toNum(j['delivery_conversion']) ?? 1,
        pricePerUnit: toNum(j['price_per_unit']) ?? 0,
        isActive: (j['is_active'] ?? true) as bool,
      );
}