enum FuelType { etanol, gasolina, diesel }

extension FuelTypeLabel on FuelType {
  String get label => switch (this) {
        FuelType.etanol => 'Etanol',
        FuelType.gasolina => 'Gasolina',
        FuelType.diesel => 'Diesel',
      };
}

class Vehicle {
  final int? id;
  final String brand;
  final String model;
  final int year;
  final String engineDisplacement; // ex.: "1.0", "2.0 Turbo"

  const Vehicle({
    this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.engineDisplacement,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'brand': brand,
        'model': model,
        'year': year,
        'engine': engineDisplacement,
      };

  factory Vehicle.fromMap(Map<String, Object?> m) => Vehicle(
        id: m['id'] as int?,
        brand: m['brand'] as String,
        model: m['model'] as String,
        year: m['year'] as int,
        engineDisplacement: m['engine'] as String,
      );
}

class Fueling {
  final int? id;
  final int vehicleId;
  final FuelType fuelType;
  final double pricePerLiter;
  final double odometer; // km
  final double liters;
  final DateTime dateTime;

  const Fueling({
    this.id,
    required this.vehicleId,
    required this.fuelType,
    required this.pricePerLiter,
    required this.odometer,
    required this.liters,
    required this.dateTime,
  });

  /// Valor total = preço por litro × litros.
  double get total => pricePerLiter * liters;

  Map<String, Object?> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'fuel_type': fuelType.name,
        'price_per_liter': pricePerLiter,
        'odometer': odometer,
        'liters': liters,
        'date_time': dateTime.toIso8601String(),
      };

  factory Fueling.fromMap(Map<String, Object?> m) => Fueling(
        id: m['id'] as int?,
        vehicleId: m['vehicle_id'] as int,
        fuelType: FuelType.values.byName(m['fuel_type'] as String),
        pricePerLiter: (m['price_per_liter'] as num).toDouble(),
        odometer: (m['odometer'] as num).toDouble(),
        liters: (m['liters'] as num).toDouble(),
        dateTime: DateTime.parse(m['date_time'] as String),
      );
}

/// Abastecimento + indicadores calculados em relação ao anterior.
/// O primeiro abastecimento é a referência inicial: distance, kmPerLiter e
/// costPerKm ficam nulos.
class FuelingStats {
  final Fueling fueling;
  final double? distance;
  final double? kmPerLiter;
  final double? costPerKm;

  const FuelingStats(this.fueling, {this.distance, this.kmPerLiter, this.costPerKm});
}

/// Considera que todos os abastecimentos completam o tanque.
List<FuelingStats> computeStats(List<Fueling> fuelings) {
  final sorted = [...fuelings]..sort((a, b) {
      final c = a.dateTime.compareTo(b.dateTime);
      return c != 0 ? c : a.odometer.compareTo(b.odometer);
    });
  final result = <FuelingStats>[];
  for (var i = 0; i < sorted.length; i++) {
    if (i == 0) {
      result.add(FuelingStats(sorted[i]));
      continue;
    }
    final distance = sorted[i].odometer - sorted[i - 1].odometer;
    if (distance <= 0 || sorted[i].liters <= 0) {
      result.add(FuelingStats(sorted[i], distance: distance));
      continue;
    }
    result.add(FuelingStats(
      sorted[i],
      distance: distance,
      kmPerLiter: distance / sorted[i].liters,
      costPerKm: sorted[i].total / distance,
    ));
  }
  return result;
}
