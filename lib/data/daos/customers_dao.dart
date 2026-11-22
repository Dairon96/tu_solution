import 'package:drift/drift.dart';

import '../../models/enums.dart';
import '../../models/view_data.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

part 'customers_dao.g.dart';

@DriftAccessor(tables: [Customers, Devices, RepairOrders])
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {
  CustomersDao(super.attachedDatabase);

  /// Clientes con su cantidad de equipos y órdenes abiertas.
  Stream<List<CustomerWithStats>> watchAll({String search = ''}) {
    final deviceCount = devices.id.count(distinct: true);
    final openCount = repairOrders.id.count(
      distinct: true,
      filter: repairOrders.status.isInValues(OrderStatus.openStatuses),
    );

    final query = select(customers).join([
      leftOuterJoin(devices, devices.customerId.equalsExp(customers.id)),
      leftOuterJoin(
        repairOrders,
        repairOrders.deviceId.equalsExp(devices.id),
      ),
    ])
      ..addColumns([deviceCount, openCount])
      ..groupBy([customers.id])
      ..orderBy([OrderingTerm.asc(customers.name)]);

    final term = search.trim();
    if (term.isNotEmpty) {
      query.where(
        customers.name.like('%$term%') | customers.phone.like('%$term%'),
      );
    }

    return query.watch().map(
          (rows) => rows
              .map(
                (r) => CustomerWithStats(
                  customer: r.readTable(customers),
                  devices: r.read(deviceCount) ?? 0,
                  openOrders: r.read(openCount) ?? 0,
                ),
              )
              .toList(),
        );
  }

  Stream<Customer?> watchById(int id) =>
      (select(customers)..where((c) => c.id.equals(id))).watchSingleOrNull();

  Future<Customer?> findByPhone(String phone) =>
      (select(customers)..where((c) => c.phone.equals(phone.trim())))
          .getSingleOrNull();

  Future<List<Customer>> searchByNameOrPhone(String term) {
    final t = term.trim();
    return (select(customers)
          ..where((c) => c.name.like('%$t%') | c.phone.like('%$t%'))
          ..orderBy([(c) => OrderingTerm.asc(c.name)])
          ..limit(20))
        .get();
  }

  Future<int> create(String name, String phone) => into(customers).insert(
        CustomersCompanion.insert(name: name.trim(), phone: phone.trim()),
      );

  Future<void> updateCustomer(int id, String name, String phone) =>
      (update(customers)..where((c) => c.id.equals(id))).write(
        CustomersCompanion(name: Value(name.trim()), phone: Value(phone.trim())),
      );

  // ---------- Equipos ----------

  /// Equipos de un cliente con la cantidad de veces que vinieron.
  Stream<List<DeviceWithVisits>> watchDevicesOf(int customerId) {
    final visits = repairOrders.id.count();
    final query = select(devices).join([
      leftOuterJoin(repairOrders, repairOrders.deviceId.equalsExp(devices.id)),
    ])
      ..where(devices.customerId.equals(customerId))
      ..addColumns([visits])
      ..groupBy([devices.id])
      ..orderBy([OrderingTerm.asc(devices.brand)]);

    return query.watch().map(
          (rows) => rows
              .map(
                (r) => DeviceWithVisits(
                  device: r.readTable(devices),
                  visits: r.read(visits) ?? 0,
                ),
              )
              .toList(),
        );
  }

  Future<List<Device>> devicesOf(int customerId) =>
      (select(devices)..where((d) => d.customerId.equals(customerId))).get();

  Stream<Device?> watchDevice(int id) =>
      (select(devices)..where((d) => d.id.equals(id))).watchSingleOrNull();

  Future<Device?> findDeviceBySerial(String serial) =>
      (select(devices)..where((d) => d.serialNumber.equals(serial.trim())))
          .getSingleOrNull();

  Future<int> createDevice(DevicesCompanion device) =>
      into(devices).insert(device);
}
