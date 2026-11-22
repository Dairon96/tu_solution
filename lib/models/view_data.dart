import '../data/database/app_database.dart';
import 'enums.dart';

/// Datos combinados (resultado de JOINs) que consumen las vistas.

/// Fila de la lista de órdenes: orden + equipo + dueño + técnico.
class OrderSummary {
  const OrderSummary({
    required this.order,
    required this.device,
    required this.customer,
    this.technician,
  });

  final RepairOrder order;
  final Device device;
  final Customer customer;
  final Technician? technician;

  OrderStatus get status => order.status;
  bool get isTaken => order.technicianId != null;
  String get deviceLabel => '${device.brand} ${device.model}';
}

/// Repuesto usado dentro de una orden, con los datos del inventario.
class OrderPartLine {
  const OrderPartLine({required this.line, required this.part});

  final OrderPart line;
  final Part part;

  double get subtotal => line.quantity * line.unitPrice;
}

/// Todo lo necesario para la pantalla de detalle de una orden.
class OrderDetail {
  const OrderDetail({
    required this.summary,
    required this.labor,
    required this.parts,
    this.receivedBy,
  });

  final OrderSummary summary;
  final List<LaborItem> labor;
  final List<OrderPartLine> parts;
  final Technician? receivedBy;

  double get laborTotal => labor.fold(0, (sum, l) => sum + l.cost);
  double get partsTotal => parts.fold(0, (sum, p) => sum + p.subtotal);

  /// Costo total = mano de obra + repuestos.
  double get total => laborTotal + partsTotal;
}

/// Carga de trabajo de un técnico.
class TechnicianWorkload {
  const TechnicianWorkload({
    required this.technician,
    required this.inRepair,
    required this.ready,
  });

  final Technician technician;

  /// Órdenes tomadas que están en reparación.
  final int inRepair;

  /// Órdenes que reparó y esperan a ser entregadas.
  final int ready;

  int get total => inRepair + ready;
}

/// Equipo con su cantidad de visitas (para el historial del cliente).
class DeviceWithVisits {
  const DeviceWithVisits({required this.device, required this.visits});

  final Device device;
  final int visits;
}

/// Cliente con datos agregados para la lista de clientes.
class CustomerWithStats {
  const CustomerWithStats({
    required this.customer,
    required this.devices,
    required this.openOrders,
  });

  final Customer customer;
  final int devices;
  final int openOrders;
}
