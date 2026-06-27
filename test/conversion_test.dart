import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_system/core/conversion.dart';

void main() {
  test('2 kg at 60 pc/kg = 120 pc', () {
    expect(deliveryToBase(2, 60), 120);
  });

  test('120 pc at 60 pc/kg = 2 kg', () {
    expect(baseToDelivery(120, 60), 2);
  });

  test('zero conversion is safe', () {
    expect(baseToDelivery(120, 0), 0);
  });

  test('90 pc at 60 pc/kg splits to 1 kg + 30 pc', () {
    final r = splitDelivery(90, 60);
    expect(r.deliveryWhole, 1);
    expect(r.baseRemainder, 30);
  });

  test('exact multiple leaves no remainder', () {
    final r = splitDelivery(120, 60);
    expect(r.deliveryWhole, 2);
    expect(r.baseRemainder, 0);
  });
}