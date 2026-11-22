// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_dao.dart';

// ignore_for_file: type=lint
mixin _$OrdersDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomersTable get customers => attachedDatabase.customers;
  $DevicesTable get devices => attachedDatabase.devices;
  $TechniciansTable get technicians => attachedDatabase.technicians;
  $RepairOrdersTable get repairOrders => attachedDatabase.repairOrders;
  $LaborItemsTable get laborItems => attachedDatabase.laborItems;
  $PartsTable get parts => attachedDatabase.parts;
  $OrderPartsTable get orderParts => attachedDatabase.orderParts;
  OrdersDaoManager get managers => OrdersDaoManager(this);
}

class OrdersDaoManager {
  final _$OrdersDaoMixin _db;
  OrdersDaoManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
  $$TechniciansTableTableManager get technicians =>
      $$TechniciansTableTableManager(_db.attachedDatabase, _db.technicians);
  $$RepairOrdersTableTableManager get repairOrders =>
      $$RepairOrdersTableTableManager(_db.attachedDatabase, _db.repairOrders);
  $$LaborItemsTableTableManager get laborItems =>
      $$LaborItemsTableTableManager(_db.attachedDatabase, _db.laborItems);
  $$PartsTableTableManager get parts =>
      $$PartsTableTableManager(_db.attachedDatabase, _db.parts);
  $$OrderPartsTableTableManager get orderParts =>
      $$OrderPartsTableTableManager(_db.attachedDatabase, _db.orderParts);
}
