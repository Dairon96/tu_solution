import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/daos/customers_dao.dart';
import '../data/daos/orders_dao.dart';
import '../data/daos/parts_dao.dart';
import '../data/daos/technicians_dao.dart';
import '../data/database/app_database.dart';

/// Única instancia de la base de datos para toda la app.
/// En las pruebas se sobreescribe con una base en memoria.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final techniciansDaoProvider =
    Provider<TechniciansDao>((ref) => ref.watch(appDatabaseProvider).techniciansDao);

final customersDaoProvider =
    Provider<CustomersDao>((ref) => ref.watch(appDatabaseProvider).customersDao);

final partsDaoProvider =
    Provider<PartsDao>((ref) => ref.watch(appDatabaseProvider).partsDao);

final ordersDaoProvider =
    Provider<OrdersDao>((ref) => ref.watch(appDatabaseProvider).ordersDao);
