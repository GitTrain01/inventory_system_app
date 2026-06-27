import '../models/product.dart';

/// DELIVERY units -> BASE units.  e.g. 2 kg at 60 pc/kg = 120 pc.
num deliveryToBase(num deliveryQty, num conversion) => deliveryQty * conversion;

/// BASE units -> DELIVERY units.  e.g. 120 pc at 60 pc/kg = 2 kg.
num baseToDelivery(num baseQty, num conversion) =>
    conversion == 0 ? 0 : baseQty / conversion;

/// Split base qty into whole delivery units + leftover base units.
/// e.g. 90 pc at 60 pc/kg -> (1 kg, 30 pc). Drives the Pack+Pcs display.
({int deliveryWhole, num baseRemainder}) splitDelivery(
    num baseQty, num conversion) {
  if (conversion <= 0) return (deliveryWhole: 0, baseRemainder: baseQty);
  final whole = baseQty ~/ conversion;
  final remainder = baseQty - (whole * conversion);
  return (deliveryWhole: whole, baseRemainder: remainder);
}

extension ProductConversion on Product {
  /// Peso value of a base-unit quantity of this product.
  num stockValue(num baseQty) => baseQty * pricePerUnit;

  /// True when this product is counted in two units (Pack + Pcs).
  bool get hasDeliveryUnit =>
      deliveryUnit != null && deliveryUnit!.trim().isNotEmpty && deliveryConversion > 1;
}