/// sold = (opening + delivered) − closing   [saleable only]
num computeSold({
  required num opening,
  required num delivered,
  required num closing,
}) =>
    (opening + delivered) - closing;

/// value = sold × price_per_unit
num computeValue({required num sold, required num pricePerUnit}) =>
    sold * pricePerUnit;

/// discrepancy = (counted_cash + counted_coins + expenses) − sales
/// Negative = short, positive = over, zero = balanced.
num computeDiscrepancy({
  required num cash,
  required num coins,
  required num expenses,
  required num sales,
}) =>
    (cash + coins + expenses) - sales;