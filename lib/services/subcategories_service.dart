import '../core/supabase_client.dart';
import '../models/subcategory.dart';

class SubcategoriesService {
  Future<List<Subcategory>> listForBranch(String branchId) async {
    final rows = await supabase
        .from('subcategories')
        .select()
        .eq('branch_id', branchId)
        .order('sort_order')
        .order('name');
    return rows.map<Subcategory>((r) => Subcategory.fromJson(r)).toList();
  }

  Future<void> add(String branchId, String name, {int sortOrder = 0}) async {
    await supabase.from('subcategories').insert({
      'branch_id': branchId,
      'name': name,
      'sort_order': sortOrder,
    });
  }

  /// Rename cascades to products, since they link by name string.
  Future<void> rename({
    required String id,
    required String branchId,
    required String oldName,
    required String newName,
  }) async {
    await supabase.from('subcategories').update({'name': newName}).eq('id', id);
    await supabase
        .from('products')
        .update({'subcategory': newName})
        .eq('branch_id', branchId)
        .eq('subcategory', oldName);
  }

  /// Delete reassigns affected products to 'Uncategorized' first.
  Future<void> delete({
    required String id,
    required String branchId,
    required String name,
  }) async {
    await supabase
        .from('products')
        .update({'subcategory': 'Uncategorized'})
        .eq('branch_id', branchId)
        .eq('subcategory', name);
    await supabase.from('subcategories').delete().eq('id', id);
  }
}

final subcategoriesService = SubcategoriesService();