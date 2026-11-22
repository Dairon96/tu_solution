import 'package:drift/drift.dart';

import '../../models/enums.dart';
import '../../models/view_data.dart';
import '../../models/workshop_exception.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

part 'orders_dao.g.dart';

/// Datos para registrar la entrada de un equipo al taller.
class ReceptionData {
  const ReceptionData({
    required this.customerName,
    required this.customerPhone,
    required this.deviceType,
    required this.brand,
    required this.model,
    required this.serialNumber,
    required this.reportedFault,
    required this.receivedById,
  });

  final String customerName;
  final String customerPhone;
  final DeviceType deviceType;
  final String brand;
  final String model;
  final String serialNumber;
  final String reportedFault;
  final int receivedById;
}

@DriftAccessor(
  tables: [
    RepairOrders,
    Devices,
    Customers,
    Technicians,
    LaborItems,
    OrderParts,
    Parts,
  ],
)
class OrdersDao extends DatabaseAccessor<AppDatabase> with _$OrdersDaoMixin {
  OrdersDao(super.attachedDatabase);

  // ---------------------------------------------------------------------------
  // Consultas
  // ---------------------------------------------------------------------------

  /// Orden + equipo + cliente + técnico responsable.
  JoinedSelectStatement<HasResultSet, dynamic> _summaryQuery() {
    return select(repairOrders).join([
      innerJoin(devices, devices.id.equalsExp(repairOrders.deviceId)),
      innerJoin(customers, customers.id.equalsExp(devices.customerId)),
      leftOuterJoin(
        technicians,
        technicians.id.equalsExp(repairOrders.technicianId),
      ),
    ]);
  }

  OrderSummary _readSummary(TypedResult row) => OrderSummary(
        order: row.readTable(repairOrders),
        device: row.readTable(devices),
        customer: row.readTable(customers),
        technician: row.readTableOrNull(technicians),
      );

  /// Lista de órdenes con filtros opcionales.
  Stream<List<OrderSummary>> watchOrders({
    Set<OrderStatus>? statuses,
    int? technicianId,
    int? deviceId,
    int? customerId,
    bool onlyUntaken = false,
    String search = '',
  }) {
    final query = _summaryQuery();
    if (statuses != null && statuses.isNotEmpty) {
      query.where(repairOrders.status.isInValues(statuses));
    }
    if (technicianId != null) {
      query.where(repairOrders.technicianId.equals(technicianId));
    }
    if (deviceId != null) query.where(repairOrders.deviceId.equals(deviceId));
    if (customerId != null) query.where(devices.customerId.equals(customerId));
    if (onlyUntaken) query.where(repairOrders.technicianId.isNull());

    final term = search.trim();
    if (term.isNotEmpty) {
      final like = '%$term%';
      Expression<bool> cond = customers.name.like(like) |
          customers.phone.like(like) |
          devices.brand.like(like) |
          devices.model.like(like) |
          devices.serialNumber.like(like);
      final asNumber = int.tryParse(term.replaceAll('#', ''));
      if (asNumber != null) cond = cond | repairOrders.id.equals(asNumber);
      query.where(cond);
    }

    query.orderBy([OrderingTerm.desc(repairOrders.receivedAt)]);
    return query.watch().map((rows) => rows.map(_readSummary).toList());
  }

  /// Cantidad de órdenes en cada estado.
  Stream<Map<OrderStatus, int>> watchStatusCounts() {
    final count = repairOrders.id.count();
    final query = selectOnly(repairOrders)
      ..addColumns([repairOrders.status, count])
      ..groupBy([repairOrders.status]);

    return query.watch().map((rows) {
      final result = {for (final s in OrderStatus.values) s: 0};
      for (final r in rows) {
        final status = repairOrders.status.converter
            .fromSql(r.read(repairOrders.status)!);
        result[status] = r.read(count) ?? 0;
      }
      return result;
    });
  }

  /// Detalle reactivo de una orden: se vuelve a emitir cuando cambian la
  /// orden, sus trabajos, sus repuestos o el inventario.
  Stream<OrderDetail?> watchDetail(int orderId) {
    return customSelect(
      'SELECT 1',
      readsFrom: {
        repairOrders,
        laborItems,
        orderParts,
        parts,
        technicians,
        devices,
        customers,
      },
    ).watch().asyncMap((_) => loadDetail(orderId));
  }

  Future<OrderDetail?> loadDetail(int orderId) async {
    final row = await (_summaryQuery()
          ..where(repairOrders.id.equals(orderId)))
        .getSingleOrNull();
    if (row == null) return null;
    final summary = _readSummary(row);

    final labor = await (select(laborItems)
          ..where((l) => l.orderId.equals(orderId))
          ..orderBy([(l) => OrderingTerm.asc(l.createdAt)]))
        .get();

    final partRows = await (select(orderParts).join([
      innerJoin(parts, parts.id.equalsExp(orderParts.partId)),
    ])
          ..where(orderParts.orderId.equals(orderId))
          ..orderBy([OrderingTerm.asc(orderParts.createdAt)]))
        .get();

    final receivedById = summary.order.receivedById;
    final receivedBy = receivedById == null
        ? null
        : await (select(technicians)
              ..where((t) => t.id.equals(receivedById)))
            .getSingleOrNull();

    return OrderDetail(
      summary: summary,
      labor: labor,
      parts: partRows
          .map(
            (r) => OrderPartLine(
              line: r.readTable(orderParts),
              part: r.readTable(parts),
            ),
          )
          .toList(),
      receivedBy: receivedBy,
    );
  }

  Future<RepairOrder> _getOrder(int orderId) async {
    final order = await (select(repairOrders)
          ..where((o) => o.id.equals(orderId)))
        .getSingleOrNull();
    if (order == null) throw const WorkshopException('La orden no existe.');
    return order;
  }

  Future<String> _technicianName(int id) async {
    final t = await (select(technicians)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return t?.name ?? 'otro técnico';
  }

  // ---------------------------------------------------------------------------
  // Recepción
  // ---------------------------------------------------------------------------

  /// Registra la entrada de un equipo. Reutiliza el cliente (por teléfono) y
  /// el equipo (por número de serie) si ya existían, para conservar el
  /// historial. Devuelve el id de la nueva orden.
  Future<int> receiveDevice(ReceptionData data) {
    return transaction(() async {
      // 1. Cliente: se busca por teléfono.
      final phone = data.customerPhone.trim();
      var customer = await (select(customers)
            ..where((c) => c.phone.equals(phone)))
          .getSingleOrNull();
      final customerId = customer?.id ??
          await into(customers).insert(
            CustomersCompanion.insert(
              name: data.customerName.trim(),
              phone: phone,
            ),
          );

      // 2. Equipo: se busca por número de serie.
      final serial = data.serialNumber.trim();
      final device = await (select(devices)
            ..where((d) => d.serialNumber.equals(serial)))
          .getSingleOrNull();

      int deviceId;
      if (device == null) {
        deviceId = await into(devices).insert(
          DevicesCompanion.insert(
            customerId: customerId,
            type: data.deviceType,
            brand: data.brand.trim(),
            model: data.model.trim(),
            serialNumber: serial,
          ),
        );
      } else {
        deviceId = device.id;

        // Un equipo no puede tener dos órdenes abiertas a la vez.
        final open = await (select(repairOrders)
              ..where(
                (o) =>
                    o.deviceId.equals(deviceId) &
                    o.status.isInValues(OrderStatus.openStatuses),
              ))
            .get();
        if (open.isNotEmpty) {
          throw WorkshopException(
            'Este equipo ya está en el taller (orden #${open.first.id}).',
          );
        }

        // Si cambió de dueño, se actualiza el dueño actual.
        if (device.customerId != customerId) {
          await (update(devices)..where((d) => d.id.equals(deviceId)))
              .write(DevicesCompanion(customerId: Value(customerId)));
        }
      }

      return into(repairOrders).insert(
        RepairOrdersCompanion.insert(
          deviceId: deviceId,
          reportedFault: data.reportedFault.trim(),
          status: OrderStatus.recibida,
          receivedById: Value(data.receivedById),
          receivedAt: DateTime.now(),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Responsable de la orden
  // ---------------------------------------------------------------------------

  /// Un técnico toma la orden. La actualización solo se aplica si la orden
  /// todavía no tiene responsable, así dos técnicos no pueden tomarla a la vez.
  Future<void> takeOrder(int orderId, int technicianId) {
    return transaction(() async {
      final order = await _getOrder(orderId);
      if (!order.status.isOpen) {
        throw const WorkshopException('La orden ya está cerrada.');
      }
      if (order.technicianId != null) {
        if (order.technicianId == technicianId) return;
        final name = await _technicianName(order.technicianId!);
        throw WorkshopException('Esta orden ya la tomó $name.');
      }

      final changed = await (update(repairOrders)
            ..where((o) => o.id.equals(orderId) & o.technicianId.isNull()))
          .write(
        RepairOrdersCompanion(
          technicianId: Value(technicianId),
          takenAt: Value(DateTime.now()),
          status: order.status == OrderStatus.recibida
              ? const Value(OrderStatus.enReparacion)
              : const Value.absent(),
        ),
      );
      if (changed == 0) {
        throw const WorkshopException('Otro técnico acaba de tomar la orden.');
      }
    });
  }

  /// Pasa la orden a otro técnico.
  Future<void> reassign(int orderId, int technicianId) async {
    final order = await _getOrder(orderId);
    if (!order.status.isOpen) {
      throw const WorkshopException('La orden ya está cerrada.');
    }
    await (update(repairOrders)..where((o) => o.id.equals(orderId))).write(
      RepairOrdersCompanion(
        technicianId: Value(technicianId),
        takenAt: Value(DateTime.now()),
        status: order.status == OrderStatus.recibida
            ? const Value(OrderStatus.enReparacion)
            : const Value.absent(),
      ),
    );
  }

  /// El técnico suelta la orden: vuelve a "recibida" y sin responsable.
  Future<void> releaseOrder(int orderId) async {
    final order = await _getOrder(orderId);
    if (order.status != OrderStatus.enReparacion) {
      throw const WorkshopException(
        'Solo se puede liberar una orden en reparación.',
      );
    }
    await (update(repairOrders)..where((o) => o.id.equals(orderId))).write(
      const RepairOrdersCompanion(
        technicianId: Value(null),
        takenAt: Value(null),
        status: Value(OrderStatus.recibida),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cambios de estado
  // ---------------------------------------------------------------------------

  Future<void> markReady(int orderId) {
    return transaction(() async {
      final order = await _getOrder(orderId);
      if (order.status != OrderStatus.enReparacion) {
        throw const WorkshopException(
          'Solo una orden en reparación puede marcarse como lista.',
        );
      }
      final labor = await (select(laborItems)
            ..where((l) => l.orderId.equals(orderId)))
          .get();
      if (labor.isEmpty) {
        throw const WorkshopException(
          'Anota al menos un trabajo realizado antes de marcarla como lista.',
        );
      }
      await _setStatus(
        orderId,
        OrderStatus.lista,
        finishedAt: Value(DateTime.now()),
      );
    });
  }

  /// Si al probar el equipo falla, la orden vuelve a reparación.
  Future<void> reopen(int orderId) async {
    final order = await _getOrder(orderId);
    if (order.status != OrderStatus.lista) {
      throw const WorkshopException('Solo se puede reabrir una orden lista.');
    }
    await _setStatus(
      orderId,
      OrderStatus.enReparacion,
      finishedAt: const Value(null),
    );
  }

  Future<void> deliver(int orderId) async {
    final order = await _getOrder(orderId);
    if (order.status != OrderStatus.lista) {
      throw const WorkshopException(
        'Solo se puede entregar una orden que está lista.',
      );
    }
    await _setStatus(
      orderId,
      OrderStatus.entregada,
      closedAt: Value(DateTime.now()),
    );
  }

  /// Cancela la orden y devuelve al almacén los repuestos que se habían
  /// descontado, para que el stock siga cuadrando.
  Future<void> cancel(int orderId, {String? reason}) {
    return transaction(() async {
      final order = await _getOrder(orderId);
      if (!order.status.isOpen) {
        throw const WorkshopException('La orden ya está cerrada.');
      }
      final lines = await (select(orderParts)
            ..where((p) => p.orderId.equals(orderId)))
          .get();
      for (final line in lines) {
        await _changeStock(line.partId, line.quantity);
      }
      await (delete(orderParts)..where((p) => p.orderId.equals(orderId))).go();

      final note = reason?.trim();
      await (update(repairOrders)..where((o) => o.id.equals(orderId))).write(
        RepairOrdersCompanion(
          status: const Value(OrderStatus.cancelada),
          closedAt: Value(DateTime.now()),
          notes: note == null || note.isEmpty
              ? const Value.absent()
              : Value(_appendNote(order.notes, 'Cancelada: $note')),
        ),
      );
    });
  }

  Future<void> updateNotes(int orderId, String notes) =>
      (update(repairOrders)..where((o) => o.id.equals(orderId))).write(
        RepairOrdersCompanion(
          notes: Value(notes.trim().isEmpty ? null : notes.trim()),
        ),
      );

  Future<void> _setStatus(
    int orderId,
    OrderStatus status, {
    Value<DateTime?> finishedAt = const Value.absent(),
    Value<DateTime?> closedAt = const Value.absent(),
  }) {
    return (update(repairOrders)..where((o) => o.id.equals(orderId))).write(
      RepairOrdersCompanion(
        status: Value(status),
        finishedAt: finishedAt,
        closedAt: closedAt,
      ),
    );
  }

  String _appendNote(String? current, String extra) =>
      current == null || current.isEmpty ? extra : '$current\n$extra';

  // ---------------------------------------------------------------------------
  // Trabajos (mano de obra)
  // ---------------------------------------------------------------------------

  Future<void> _ensureWorkAllowed(int orderId) async {
    final order = await _getOrder(orderId);
    if (!order.status.allowsWork) {
      throw const WorkshopException(
        'Solo se anotan trabajos y repuestos en órdenes en reparación.',
      );
    }
  }

  Future<void> addLabor(int orderId, String description, double cost) {
    return transaction(() async {
      await _ensureWorkAllowed(orderId);
      await into(laborItems).insert(
        LaborItemsCompanion.insert(
          orderId: orderId,
          description: description.trim(),
          cost: cost,
        ),
      );
    });
  }

  Future<void> removeLabor(int laborId) {
    return transaction(() async {
      final item = await (select(laborItems)
            ..where((l) => l.id.equals(laborId)))
          .getSingle();
      await _ensureWorkAllowed(item.orderId);
      await (delete(laborItems)..where((l) => l.id.equals(laborId))).go();
    });
  }

  // ---------------------------------------------------------------------------
  // Repuestos usados
  // ---------------------------------------------------------------------------

  /// Usa [quantity] unidades de un repuesto en la orden y las descuenta del
  /// inventario. Devuelve el repuesto con las existencias actualizadas.
  Future<Part> addPart(int orderId, int partId, int quantity) {
    if (quantity <= 0) {
      throw const WorkshopException('La cantidad debe ser mayor que cero.');
    }
    return transaction(() async {
      await _ensureWorkAllowed(orderId);
      final part = await (select(parts)..where((p) => p.id.equals(partId)))
          .getSingle();
      if (part.stock < quantity) {
        throw WorkshopException(
          'No hay suficiente "${part.name}": quedan ${part.stock}.',
        );
      }

      await _changeStock(partId, -quantity);

      // Si el repuesto ya estaba en la orden se suma a la misma línea.
      final existing = await (select(orderParts)
            ..where((l) => l.orderId.equals(orderId) & l.partId.equals(partId)))
          .getSingleOrNull();
      if (existing != null) {
        await (update(orderParts)..where((l) => l.id.equals(existing.id)))
            .write(
          OrderPartsCompanion(quantity: Value(existing.quantity + quantity)),
        );
      } else {
        await into(orderParts).insert(
          OrderPartsCompanion.insert(
            orderId: orderId,
            partId: partId,
            quantity: quantity,
            unitPrice: part.price,
          ),
        );
      }
      return part.copyWith(stock: part.stock - quantity);
    });
  }

  /// Quita un repuesto de la orden y lo devuelve al almacén.
  Future<void> removePartLine(int lineId) {
    return transaction(() async {
      final line = await (select(orderParts)
            ..where((l) => l.id.equals(lineId)))
          .getSingle();
      await _ensureWorkAllowed(line.orderId);
      await _changeStock(line.partId, line.quantity);
      await (delete(orderParts)..where((l) => l.id.equals(lineId))).go();
    });
  }

  Future<void> _changeStock(int partId, int delta) {
    return customUpdate(
      'UPDATE parts SET stock = stock + ? WHERE id = ?',
      variables: [Variable.withInt(delta), Variable.withInt(partId)],
      updates: {parts},
    );
  }
}
