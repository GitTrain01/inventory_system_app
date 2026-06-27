import '../models/product.dart';

class WorksheetLine {
  final Product product;
  final num opening;          // base units (pc)
  final num delivered;        // base units (pc)
  final num? existingClosing; // from a saved end_of_day_sale, if any
  final bool existingLow;     // consumable_checked

  const WorksheetLine({
    required this.product,
    required this.opening,
    required this.delivered,
    this.existingClosing,
    this.existingLow = false,
  });

  num get available => opening + delivered;
  bool get isConsumable => product.category == 'Consumable';
}