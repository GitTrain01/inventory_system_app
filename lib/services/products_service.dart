import '../core/supabase_client.dart';
import '../models/product.dart';

class ProductsService {
  Future<List<Product>> listForBranch(String branchId,
      {bool activeOnly = false}) async {
    var query = supabase.from('products').select().eq('branch_id', branchId);
    if (activeOnly) query = query.eq('is_active', true);
    final rows = await query.order('name');
    return rows.map<Product>((r) => Product.fromJson(r)).toList();
  }

  Future<void> create({
    required String branchId,
    required String name,
    String? category,
    String? subcategory,
    required String unit,
    String? deliveryUnit,
    required num deliveryConversion,
    required num pricePerUnit,
    required bool isActive,
  }) async {
    await supabase.from('products').insert({
      'branch_id': branchId,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'unit': unit,
      'delivery_unit': deliveryUnit,
      'delivery_conversion': deliveryConversion,
      'price_per_unit': pricePerUnit,
      'is_active': isActive,
    });
  }

  Future<void> update(
    String id, {
    required String name,
    String? category,
    String? subcategory,
    required String unit,
    String? deliveryUnit,
    required num deliveryConversion,
    required num pricePerUnit,
    required bool isActive,
  }) async {
    await supabase.from('products').update({
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'unit': unit,
      'delivery_unit': deliveryUnit,
      'delivery_conversion': deliveryConversion,
      'price_per_unit': pricePerUnit,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> setActive(String id, bool isActive) async {
    await supabase.from('products').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
    Future<void> delete(String id) async {
    await supabase.from('products').delete().eq('id', id);
  }
}

final productsService = ProductsService();