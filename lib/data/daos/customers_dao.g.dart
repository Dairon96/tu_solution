// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customers_dao.dart';

// ignore_for_file: type=lint
mixin _$CustomersDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomersTable get customers => attachedDatabase.customers;
  $DevicesTable get devices => attachedDatabase.devices;
  $TechniciansTable get technicians => attachedDatabase.technicians;
  $RepairOrdersTable get repairOrders => attachedDatabase.repairOrders;
  CustomersDaoManager get managers => CustomersDaoManager(this);
}

class CustomersDaoManager {
  final _$CustomersDaoMixin _db;
  CustomersDaoManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
  $$TechniciansTableTableManager get technicians =>
      $$TechniciansTableTableManager(_db.attachedDatabase, _db.technicians);
  $$RepairOrdersTableTableManager get repairOrders =>
      $$RepairOrdersTableTableManager(_db.attachedDatabase, _db.repairOrders);
}
