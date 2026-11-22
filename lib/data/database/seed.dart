import 'package:drift/drift.dart';

import '../../models/enums.dart';
import 'app_database.dart';

/// Datos iniciales. Se ejecuta una sola vez, al crear la base de datos.
///
/// Siempre se crean los tres técnicos del taller. Con [withDemo] además se
/// cargan repuestos, clientes, equipos y órdenes de ejemplo para la demo.
Future<void> seedInitialData(AppDatabase db, {required bool withDemo}) async {
  final techIds = <int>[];
  for (final name in ['Carlos Pérez', 'Laura Gómez', 'Miguel Torres']) {
    techIds.add(
      await db
          .into(db.technicians)
          .insert(TechniciansCompanion.insert(name: name)),
    );
  }
  if (!withDemo) return;

  // ---------------- Repuestos ----------------
  Future<int> part(String code, String name, double price, int stock,
          [int minStock = 2]) =>
      db.into(db.parts).insert(
            PartsCompanion.insert(
              code: code,
              name: name,
              price: price,
              stock: Value(stock),
              minStock: Value(minStock),
            ),
          );

  final pantallaA54 = await part('PAN-SA54', 'Pantalla Samsung A54', 85, 4);
  final pantallaIp11 = await part('PAN-IP11', 'Pantalla iPhone 11', 70, 1);
  final bateriaIp11 = await part('BAT-IP11', 'Batería iPhone 11', 25, 6);
  final bateriaRn12 = await part('BAT-RN12', 'Batería Redmi Note 12', 18, 2);
  final conectorC = await part('CON-USBC', 'Conector de carga USB-C', 6, 12, 4);
  await part('CON-LIGHT', 'Conector de carga Lightning', 8, 3, 3);
  await part('CAM-SA54', 'Módulo de cámara Samsung A54', 40, 2);
  final tecladoHp = await part('TEC-HP15', 'Teclado laptop HP 15', 35, 3);
  await part('SSD-512', 'Disco SSD 512 GB', 45, 5);
  await part('PAS-TERM', 'Pasta térmica (jeringa)', 4, 0, 2);

  // ---------------- Clientes y equipos ----------------
  Future<int> customer(String name, String phone) => db
      .into(db.customers)
      .insert(CustomersCompanion.insert(name: name, phone: phone));

  Future<int> device(int customerId, DeviceType type, String brand,
          String model, String serial) =>
      db.into(db.devices).insert(
            DevicesCompanion.insert(
              customerId: customerId,
              type: type,
              brand: brand,
              model: model,
              serialNumber: serial,
            ),
          );

  final ana = await customer('Ana Rodríguez', '55123456');
  final jorge = await customer('Jorge Martínez', '55234567');
  final maria = await customer('María Fernández', '55345678');
  final pedro = await customer('Pedro Castillo', '55456789');
  final lucia = await customer('Lucía Hernández', '55567890');

  final anaA54 = await device(ana, DeviceType.celular, 'Samsung', 'Galaxy A54',
      'R58T12AB34C');
  final anaTab = await device(ana, DeviceType.tablet, 'Samsung', 'Galaxy Tab A8',
      'R52W90TAB01');
  final jorgeIp = await device(jorge, DeviceType.celular, 'Apple', 'iPhone 11',
      'F17ZK3IP11X');
  final mariaHp = await device(maria, DeviceType.laptop, 'HP', 'Pavilion 15',
      '5CD1234HPX');
  final pedroRn = await device(pedro, DeviceType.celular, 'Xiaomi',
      'Redmi Note 12', 'RN12P00987');
  final luciaIpad = await device(lucia, DeviceType.tablet, 'Apple',
      'iPad 9na gen', 'DMPX9IPAD77');

  // ---------------- Órdenes ----------------
  final now = DateTime.now();
  DateTime daysAgo(int d, [int h = 0]) =>
      now.subtract(Duration(days: d, hours: h));

  Future<int> order({
    required int deviceId,
    required String fault,
    required OrderStatus status,
    required int receivedBy,
    required DateTime receivedAt,
    int? technician,
    DateTime? takenAt,
    DateTime? finishedAt,
    DateTime? closedAt,
    String? notes,
  }) =>
      db.into(db.repairOrders).insert(
            RepairOrdersCompanion.insert(
              deviceId: deviceId,
              reportedFault: fault,
              status: status,
              receivedById: Value(receivedBy),
              technicianId: Value(technician),
              receivedAt: receivedAt,
              takenAt: Value(takenAt),
              finishedAt: Value(finishedAt),
              closedAt: Value(closedAt),
              notes: Value(notes),
            ),
          );

  Future<void> labor(int orderId, String description, double cost) => db
      .into(db.laborItems)
      .insert(LaborItemsCompanion.insert(
          orderId: orderId, description: description, cost: cost));

  Future<void> used(int orderId, int partId, int qty, double price) =>
      db.into(db.orderParts).insert(OrderPartsCompanion.insert(
          orderId: orderId, partId: partId, quantity: qty, unitPrice: price));

  // Historial: el iPhone de Jorge ya vino hace dos meses.
  final o1 = await order(
    deviceId: jorgeIp,
    fault: 'La batería dura muy poco.',
    status: OrderStatus.entregada,
    receivedBy: techIds[0],
    technician: techIds[1],
    receivedAt: daysAgo(60),
    takenAt: daysAgo(60),
    finishedAt: daysAgo(59),
    closedAt: daysAgo(58),
  );
  await labor(o1, 'Cambio de batería', 15);
  await used(o1, bateriaIp11, 1, 25);

  final o2 = await order(
    deviceId: mariaHp,
    fault: 'Varias teclas no responden.',
    status: OrderStatus.entregada,
    receivedBy: techIds[2],
    technician: techIds[2],
    receivedAt: daysAgo(20),
    takenAt: daysAgo(20),
    finishedAt: daysAgo(18),
    closedAt: daysAgo(17),
  );
  await labor(o2, 'Reemplazo de teclado', 20);
  await labor(o2, 'Limpieza interna', 10);
  await used(o2, tecladoHp, 1, 35);

  // Órdenes abiertas.
  final o3 = await order(
    deviceId: anaA54,
    fault: 'Pantalla rota tras una caída, el táctil no responde.',
    status: OrderStatus.enReparacion,
    receivedBy: techIds[0],
    technician: techIds[0],
    receivedAt: daysAgo(2),
    takenAt: daysAgo(1),
  );
  await labor(o3, 'Desarme y diagnóstico', 5);
  await used(o3, pantallaA54, 1, 85);

  final o4 = await order(
    deviceId: jorgeIp,
    fault: 'No carga, hay que mover el cable.',
    status: OrderStatus.lista,
    receivedBy: techIds[1],
    technician: techIds[1],
    receivedAt: daysAgo(3),
    takenAt: daysAgo(3),
    finishedAt: daysAgo(0, 3),
    notes: 'Se limpió el puerto pero estaba dañado.',
  );
  await labor(o4, 'Cambio de conector de carga', 12);
  await used(o4, conectorC, 1, 6);

  await order(
    deviceId: pedroRn,
    fault: 'Se apaga solo con 30% de batería.',
    status: OrderStatus.enReparacion,
    receivedBy: techIds[2],
    technician: techIds[1],
    receivedAt: daysAgo(1),
    takenAt: daysAgo(0, 5),
  );

  await order(
    deviceId: luciaIpad,
    fault: 'No enciende.',
    status: OrderStatus.recibida,
    receivedBy: techIds[1],
    receivedAt: daysAgo(0, 4),
  );

  await order(
    deviceId: anaTab,
    fault: 'El audio se escucha distorsionado.',
    status: OrderStatus.recibida,
    receivedBy: techIds[0],
    receivedAt: daysAgo(0, 1),
  );

  await order(
    deviceId: mariaHp,
    fault: 'Calienta mucho y se apaga.',
    status: OrderStatus.cancelada,
    receivedBy: techIds[0],
    receivedAt: daysAgo(10),
    closedAt: daysAgo(9),
    notes: 'Cancelada: el cliente decidió no repararla.',
  );

  // Silencia avisos de variables solo usadas para crear datos.
  assert(pantallaIp11 > 0 && bateriaRn12 > 0);
}
