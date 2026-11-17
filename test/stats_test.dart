import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_tracker/models.dart';

Fueling f(double km, double liters, double price, DateTime d) => Fueling(
      vehicleId: 1,
      fuelType: FuelType.gasolina,
      pricePerLiter: price,
      odometer: km,
      liters: liters,
      dateTime: d,
    );

void main() {
  test('primeiro abastecimento é referência (sem km/L e R\$/km)', () {
    final s = computeStats([f(1000, 40, 5, DateTime(2026, 1, 1))]);
    expect(s.first.kmPerLiter, isNull);
    expect(s.first.costPerKm, isNull);
  });

  test('calcula distância, km/L e R\$/km a partir do segundo', () {
    final s = computeStats([
      f(1000, 40, 5, DateTime(2026, 1, 1)),
      f(1400, 40, 5.5, DateTime(2026, 1, 10)),
    ]);
    expect(s[1].distance, 400);
    expect(s[1].kmPerLiter, closeTo(10, 1e-9));
    expect(s[1].costPerKm, closeTo(220 / 400, 1e-9));
  });

  test('total = preço × litros', () {
    expect(f(0, 10, 5.5, DateTime(2026)).total, closeTo(55, 1e-9));
  });
}
