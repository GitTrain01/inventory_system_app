import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cash_service.dart';

/// (date, shift) the cash screen is viewing.
typedef CashKey = ({String date, String shift});

final cashReportProvider =
    FutureProvider.family<Map<String, dynamic>?, CashKey>((ref, key) async {
  // branch comes from the screen via a separate arg-less call; see screen.
  return null; // placeholder; screen loads directly (see note below)
});