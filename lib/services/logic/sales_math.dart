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