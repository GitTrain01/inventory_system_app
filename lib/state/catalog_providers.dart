import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/subcategory.dart';
import '../services/products_service.dart';
import '../services/subcategories_service.dart';
import 'active_branch_provider.dart';

final subcategoriesProvider = FutureProvider<List<Subcategory>>((ref) async {
  final branch = ref.watch(activeBranchProvider);
  if (branch == null) return const [];
  return subcategoriesService.listForBranch(branch.id);
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final branch = ref.watch(activeBranchProvider);
  if (branch == null) return const [];
  return productsService.listForBranch(branch.id);
});