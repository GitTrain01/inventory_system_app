import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/delivery_plan.dart';
import '../services/delivery_service.dart';
import 'active_branch_provider.dart';

final deliveryPlansProvider = FutureProvider<List<DeliveryPlan>>((ref) async {
  final branch = ref.watch(activeBranchProvider);
  if (branch == null) return const [];
  return deliveryService.listPlans(branch.id);
});