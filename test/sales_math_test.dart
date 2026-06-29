import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_system/services/logic/sales_math.dart';

void main() {
  test('opening 630 + delivered 300, closing 500 -> sold 430', () {
    expect(computeSold(opening: 630, delivered: 300, closing: 500), 430);
  });

  test('value = 430 x 4.50 = 1935', () {
    expect(computeValue(sold: 430, pricePerUnit: 4.5), 1935);
  });

  test('available = opening + delivered', () {
    expect(computeSold(opening: 0, delivered: 930, closing: 930), 0);
  });

  test('cash 1000 + coins 200, no expenses, sales 1935 -> -735 (short)', () {
  expect(
    computeDiscrepancy(cash: 1000, coins: 200, expenses: 0, sales: 1935),
    -735,
  );
});
}