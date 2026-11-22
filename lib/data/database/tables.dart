import 'package:drift/drift.dart';

import '../../models/enums.dart';

/// Técnicos del taller. No hay autenticación: solo sirven para saber
/// quién recibió un equipo y quién es responsable de cada orden.
@DataClassName('Technician')
class Technicians extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

/// Dueños de los equipos.
@DataClassName('Customer')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get phone => text().withLength(min: 1, max: 30).unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Equipos. Un mismo equipo (identificado por su número de serie)
/// puede volver al taller muchas veces.
@DataClassName('Device')
class Devices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  TextColumn get type => textEnum<DeviceType>()();
  TextColumn get brand => text().withLength(min: 1, max: 40)();
  TextColumn get model => text().withLength(min: 1, max: 60)();
  TextColumn get serialNumber => text().withLength(min: 1, max: 60).unique()();
}

/// Inventario de repuestos.
@DataClassName('Part')
class Parts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 1, max: 30).unique()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  RealColumn get price => real()();
  IntColumn get stock => integer().withDefault(const Constant(0))();

  /// Cuando las existencias llegan a este valor o menos, el repuesto
  /// se considera "por agotarse".
  IntColumn get minStock => integer().withDefault(const Constant(2))();
}

/// Cada visita de un equipo al taller.
@DataClassName('RepairOrder')
class RepairOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deviceId => integer().references(Devices, #id)();
  TextColumn get reportedFault => text().withLength(min: 1, max: 500)();
  TextColumn get status => textEnum<OrderStatus>()();

  /// Técnico que registró la entrada del equipo.
  @ReferenceName('receivedOrders')
  IntColumn get receivedById =>
      integer().nullable().references(Technicians, #id)();

  /// Técnico responsable (quien "tomó" la orden). Null = sin tomar.
  @ReferenceName('assignedOrders')
  IntColumn get technicianId =>
      integer().nullable().references(Technicians, #id)();

  TextColumn get notes => text().nullable()();
  DateTimeColumn get receivedAt => dateTime()();
  DateTimeColumn get takenAt => dateTime().nullable()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  DateTimeColumn get closedAt => dateTime().nullable()();
}

/// Trabajos realizados (mano de obra) en una orden.
@DataClassName('LaborItem')
class LaborItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId =>
      integer().references(RepairOrders, #id, onDelete: KeyAction.cascade)();
  TextColumn get description => text().withLength(min: 1, max: 200)();
  RealColumn get cost => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Repuestos utilizados en una orden. Se guarda el precio unitario del
/// momento para que el total no cambie si luego se actualiza el inventario.
@DataClassName('OrderPart')
class OrderParts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId =>
      integer().references(RepairOrders, #id, onDelete: KeyAction.cascade)();
  IntColumn get partId => integer().references(Parts, #id)();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
