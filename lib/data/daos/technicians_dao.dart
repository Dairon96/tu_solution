import 'package:drift/drift.dart';

import '../../models/enums.dart';
import '../../models/view_data.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

part 'technicians_dao.g.dart';

@DriftAccessor(tables: [Technicians, RepairOrders])
class TechniciansDao extends DatabaseAccessor<AppDatabase>
    with _$TechniciansDaoMixin {
  TechniciansDao(super.attachedDatabase);

  Stream<List<Technician>> watchAll({bool onlyActive = false}) {
    final query = select(technicians)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    if (onlyActive) query.where((t) => t.active.equals(true));
    return query.watch();
  }

  Future<int> create(String name) =>
      into(technicians).insert(TechniciansCompanion.insert(name: name));

  Future<void> rename(int id, String name) =>
      (update(technicians)..where((t) => t.id.equals(id)))
          .write(TechniciansCompanion(name: Value(name)));

  Future<void> setActive(int id, bool active) =>
      (update(technicians)..where((t) => t.id.equals(id)))
          .write(TechniciansCompanion(active: Value(active)));

  /// Cuántas órdenes tiene cada técnico en reparación y listas.
  Stream<List<TechnicianWorkload>> watchWorkload() {
    final inRepair = repairOrders.id.count(
      filter: repairOrders.status.equalsValue(OrderStatus.enReparacion),
    );
    final ready = repairOrders.id.count(
      filter: repairOrders.status.equalsValue(OrderStatus.lista),
    );

    final query = select(technicians).join([
      leftOuterJoin(
        repairOrders,
        repairOrders.technicianId.equalsExp(technicians.id),
      ),
    ])
      ..where(technicians.active.equals(true))
      ..addColumns([inRepair, ready])
      ..groupBy([technicians.id])
      ..orderBy([OrderingTerm.asc(technicians.name)]);

    return query.watch().map(
          (rows) => rows
              .map(
                (r) => TechnicianWorkload(
                  technician: r.readTable(technicians),
                  inRepair: r.read(inRepair) ?? 0,
                  ready: r.read(ready) ?? 0,
                ),
              )
              .toList(),
        );
  }
}
