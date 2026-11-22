import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_solution/data/daos/orders_dao.dart';
import 'package:tu_solution/data/database/app_database.dart';
import 'package:tu_solution/models/enums.dart';
import 'package:tu_solution/models/workshop_exception.dart';

/// Pruebas de las reglas del taller sobre una base SQLite en memoria.
void main() {
  // Las pruebas crean varias bases en memoria a propósito.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late OrdersDao orders;
  late List<Technician> techs;

  setUp(() async {
    db = AppDatabase.forTesting(
      NativeDatabase.memory(),
      seedDemoData: false,
    );
    orders = db.ordersDao;
    techs = await db.select(db.technicians).get();
  });

  tearDown(() => db.close());

  ReceptionData reception({String serial = 'SN-1', String phone = '555'}) =>
      ReceptionData(
        customerName: 'Cliente Prueba',
        customerPhone: phone,
        deviceType: DeviceType.celular,
        brand: 'Samsung',
        model: 'A10',
        serialNumber: serial,
        reportedFault: 'No enciende',
        receivedById: techs.first.id,
      );

  Future<int> newPart({int stock = 5, int minStock = 2, double price = 10}) =>
      db.into(db.parts).insert(
            PartsCompanion.insert(
              code: 'P-$stock-$price',
              name: 'Pantalla',
              price: price,
              stock: Value(stock),
              minStock: Value(minStock),
            ),
          );

  test('se crean los tres técnicos del taller', () {
    expect(techs, hasLength(3));
  });

  test('recibir un equipo crea cliente, equipo y orden recibida', () async {
    final id = await orders.receiveDevice(reception());
    final detail = await orders.loadDetail(id);

    expect(detail!.summary.status, OrderStatus.recibida);
    expect(detail.summary.technician, isNull);
    expect(detail.receivedBy!.id, techs.first.id);
  });

  test('un equipo que vuelve reutiliza cliente y equipo (historial)', () async {
    final first = await orders.receiveDevice(reception());
    await orders.cancel(first);
    final second = await orders.receiveDevice(reception());

    expect(await db.select(db.customers).get(), hasLength(1));
    expect(await db.select(db.devices).get(), hasLength(1));
    final history = await orders
        .watchOrders(deviceId: (await orders.loadDetail(second))!.summary.device.id)
        .first;
    expect(history, hasLength(2));
  });

  test('no se puede recibir un equipo que ya está en el taller', () async {
    await orders.receiveDevice(reception());
    expect(
      () => orders.receiveDevice(reception()),
      throwsA(isA<WorkshopException>()),
    );
  });

  test('solo un técnico puede tomar la orden', () async {
    final id = await orders.receiveDevice(reception());
    await orders.takeOrder(id, techs[0].id);

    final detail = await orders.loadDetail(id);
    expect(detail!.summary.technician!.id, techs[0].id);
    expect(detail.summary.status, OrderStatus.enReparacion);

    await expectLater(
      orders.takeOrder(id, techs[1].id),
      throwsA(
        isA<WorkshopException>().having(
          (e) => e.message,
          'message',
          contains(techs[0].name),
        ),
      ),
    );
  });

  test('usar repuestos descuenta stock y calcula el total', () async {
    final partId = await newPart(stock: 5, price: 30);
    final id = await orders.receiveDevice(reception());
    await orders.takeOrder(id, techs[0].id);

    await orders.addLabor(id, 'Cambio de pantalla', 20);
    final updated = await orders.addPart(id, partId, 2);
    expect(updated.stock, 3);

    final detail = await orders.loadDetail(id);
    expect(detail!.laborTotal, 20);
    expect(detail.partsTotal, 60);
    expect(detail.total, 80);
  });

  test('no se pueden usar más repuestos de los que hay', () async {
    final partId = await newPart(stock: 1);
    final id = await orders.receiveDevice(reception());
    await orders.takeOrder(id, techs[0].id);

    expect(
      () => orders.addPart(id, partId, 2),
      throwsA(isA<WorkshopException>()),
    );
  });

  test('cancelar devuelve los repuestos al almacén', () async {
    final partId = await newPart(stock: 4);
    final id = await orders.receiveDevice(reception());
    await orders.takeOrder(id, techs[0].id);
    await orders.addPart(id, partId, 3);

    await orders.cancel(id, reason: 'No quiso repararlo');

    final part = await (db.select(db.parts)..where((p) => p.id.equals(partId)))
        .getSingle();
    expect(part.stock, 4);
    expect((await orders.loadDetail(id))!.summary.status, OrderStatus.cancelada);
  });

  test('repuestos por agotarse: stock <= mínimo', () async {
    await newPart(stock: 2, minStock: 2);
    await newPart(stock: 8, minStock: 2, price: 1);
    final low = await db.partsDao.watchLowStock().first;
    expect(low, hasLength(1));
  });

  test('flujo completo y carga de trabajo por técnico', () async {
    final id = await orders.receiveDevice(reception());
    await orders.takeOrder(id, techs[1].id);

    var load = await db.techniciansDao.watchWorkload().first;
    expect(load.firstWhere((w) => w.technician.id == techs[1].id).inRepair, 1);

    // No se puede marcar lista sin anotar trabajos.
    expect(() => orders.markReady(id), throwsA(isA<WorkshopException>()));

    await orders.addLabor(id, 'Diagnóstico', 5);
    await orders.markReady(id);
    load = await db.techniciansDao.watchWorkload().first;
    expect(load.firstWhere((w) => w.technician.id == techs[1].id).ready, 1);

    await orders.deliver(id);
    final detail = await orders.loadDetail(id);
    expect(detail!.summary.status, OrderStatus.entregada);
    expect(detail.summary.order.closedAt, isNotNull);

    // Cerrada: ya no se anotan trabajos.
    expect(
      () => orders.addLabor(id, 'Extra', 1),
      throwsA(isA<WorkshopException>()),
    );
  });

  test('los datos de demo se cargan sin errores', () async {
    final demo = AppDatabase.forTesting(
      NativeDatabase.memory(),
      seedDemoData: true,
    );
    final counts = await demo.ordersDao.watchStatusCounts().first;
    expect(counts.values.fold<int>(0, (a, b) => a + b), greaterThan(0));
    await demo.close();
  });
}
