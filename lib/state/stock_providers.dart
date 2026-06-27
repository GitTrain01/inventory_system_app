import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/live_stock.dart';
import '../services/stock_service.dart';
import 'active_branch_provider.dart';

/// product_id -> StockLevel for the active branch. Re-fetches on branch switch.
final stockMapProvider = FutureProvider<Map<String, StockLevel>>((ref) async {
  final branch = ref.watch(activeBranchProvider);
  if (branch == null) return const {};
  return stockService.mapForBranch(branch.id);
});