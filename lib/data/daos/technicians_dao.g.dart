// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technicians_dao.dart';

// ignore_for_file: type=lint
mixin _$TechniciansDaoMixin on DatabaseAccessor<AppDatabase> {
  $TechniciansTable get technicians => attachedDatabase.technicians;
  $CustomersTable get customers => attachedDatabase.customers;
  $DevicesTable get devices => attachedDatabase.devices;
  $RepairOrdersTable get repairOrders => attachedDatabase.repairOrders;
  TechniciansDaoManager get managers => TechniciansDaoManager(this);
}

class TechniciansDaoManager {
  final _$TechniciansDaoMixin _db;
  TechniciansDaoManager(this._db);
  $$TechniciansTableTableManager get technicians =>
      $$TechniciansTableTableManager(_db.attachedDatabase, _db.technicians);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
  $$RepairOrdersTableTableManager get repairOrders =>
      $$RepairOrdersTableTableManager(_db.attachedDatabase, _db.repairOrders);
}
