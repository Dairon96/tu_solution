import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../models/enums.dart';
import '../daos/customers_dao.dart';
import '../daos/orders_dao.dart';
import '../daos/parts_dao.dart';
import '../daos/technicians_dao.dart';
import 'seed.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Technicians,
    Customers,
    Devices,
    Parts,
    RepairOrders,
    LaborItems,
    OrderParts,
  ],
  daos: [TechniciansDao, CustomersDao, PartsDao, OrdersDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({this.seedDemoData = true})
      : super(driftDatabase(name: 'tu_solution'));

  /// Constructor para pruebas (base en memoria, por ejemplo).
  AppDatabase.forTesting(super.executor, {this.seedDemoData = false});

  /// Si es true, al crear la base se cargan datos de ejemplo para la demo.
  final bool seedDemoData;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedInitialData(this, withDemo: seedDemoData);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
