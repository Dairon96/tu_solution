import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../models/view_data.dart';
import '../models/workshop_exception.dart';
import '../providers/database_providers.dart';

/// Texto de búsqueda de la lista de clientes.
class CustomerSearchViewModel extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String value) => state = value;
}

final customerSearchProvider =
    NotifierProvider<CustomerSearchViewModel, String>(
  CustomerSearchViewModel.new,
);

final customersListProvider = StreamProvider<List<CustomerWithStats>>((ref) {
  final search = ref.watch(customerSearchProvider);
  return ref.watch(customersDaoProvider).watchAll(search: search);
});

final customerProvider = StreamProvider.autoDispose.family<Customer?, int>(
  (ref, id) => ref.watch(customersDaoProvider).watchById(id),
);

final customerDevicesProvider =
    StreamProvider.autoDispose.family<List<DeviceWithVisits>, int>(
  (ref, customerId) =>
      ref.watch(customersDaoProvider).watchDevicesOf(customerId),
);

/// Historial de reparaciones de un cliente (todas sus órdenes).
final customerOrdersProvider =
    StreamProvider.autoDispose.family<List<OrderSummary>, int>(
  (ref, customerId) =>
      ref.watch(ordersDaoProvider).watchOrders(customerId: customerId),
);

final deviceProvider = StreamProvider.autoDispose.family<Device?, int>(
  (ref, id) => ref.watch(customersDaoProvider).watchDevice(id),
);

/// Historial de reparaciones de un equipo.
final deviceOrdersProvider =
    StreamProvider.autoDispose.family<List<OrderSummary>, int>(
  (ref, deviceId) => ref.watch(ordersDaoProvider).watchOrders(deviceId: deviceId),
);

/// Detalles (trabajos y repuestos) de cada visita de un equipo, para ver qué
/// se le hizo cada vez.
final deviceHistoryProvider =
    StreamProvider.autoDispose.family<List<OrderDetail>, int>((ref, deviceId) {
  final dao = ref.watch(ordersDaoProvider);
  return dao.watchOrders(deviceId: deviceId).asyncMap((orders) async {
    final details = <OrderDetail>[];
    for (final o in orders) {
      final d = await dao.loadDetail(o.order.id);
      if (d != null) details.add(d);
    }
    return details;
  });
});

class CustomersViewModel {
  CustomersViewModel(this._ref);

  final Ref _ref;

  Future<void> update(int id, String name, String phone) async {
    if (name.trim().isEmpty || phone.trim().isEmpty) {
      throw const WorkshopException('Nombre y teléfono son obligatorios.');
    }
    final dao = _ref.read(customersDaoProvider);
    final other = await dao.findByPhone(phone);
    if (other != null && other.id != id) {
      throw WorkshopException('Ese teléfono ya es de ${other.name}.');
    }
    await dao.updateCustomer(id, name, phone);
  }
}

final customersViewModelProvider =
    Provider<CustomersViewModel>(CustomersViewModel.new);
