import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Persistência local com SQLite (sqflite).
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await openDatabase(
      join(await getDatabasesPath(), 'fuel_tracker.db'),
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE vehicle(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            brand TEXT NOT NULL,
            model TEXT NOT NULL,
            year INTEGER NOT NULL,
            engine TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE fueling(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicle_id INTEGER NOT NULL,
            fuel_type TEXT NOT NULL,
            price_per_liter REAL NOT NULL,
            odometer REAL NOT NULL,
            liters REAL NOT NULL,
            date_time TEXT NOT NULL,
            FOREIGN KEY(vehicle_id) REFERENCES vehicle(id) ON DELETE CASCADE
          )''');
      },
    );
    return _db!;
  }

  Future<Vehicle?> getVehicle() async {
    final db = await _database;
    final rows = await db.query('vehicle', limit: 1);
    return rows.isEmpty ? null : Vehicle.fromMap(rows.first);
  }

  Future<Vehicle> insertVehicle(Vehicle v) async {
    final db = await _database;
    // Apenas um veículo por vez.
    if ((await db.query('vehicle', limit: 1)).isNotEmpty) {
      throw StateError('Já existe um veículo cadastrado.');
    }
    final id = await db.insert('vehicle', v.toMap()..remove('id'));
    return Vehicle(
      id: id,
      brand: v.brand,
      model: v.model,
      year: v.year,
      engineDisplacement: v.engineDisplacement,
    );
  }

  /// Exclui o veículo e, em cascata, seus abastecimentos.
  Future<void> deleteVehicle(int id) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('fueling', where: 'vehicle_id = ?', whereArgs: [id]);
      await txn.delete('vehicle', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Fueling>> getFuelings(int vehicleId) async {
    final db = await _database;
    final rows = await db.query(
      'fueling',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date_time ASC',
    );
    return rows.map(Fueling.fromMap).toList();
  }

  Future<void> insertFueling(Fueling f) async {
    final db = await _database;
    await db.insert('fueling', f.toMap()..remove('id'));
  }

  Future<void> deleteFueling(int id) async {
    final db = await _database;
    await db.delete('fueling', where: 'id = ?', whereArgs: [id]);
  }
}
