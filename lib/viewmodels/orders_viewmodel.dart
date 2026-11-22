import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/daos/orders_dao.dart';
import '../data/database/app_database.dart';
import '../models/enums.dart';
import '../models/view_data.dart';
import '../providers/database_providers.dart';

/// Filtros de la lista de órdenes.
enum OrdersScope {
  abiertas('Abiertas'),
  sinTomar('Sin tomar'),
  recibida('Recibidas'),
  enReparacion('En reparación'),
  lista('Listas'),
  entregada('Entregadas'),
  cancelada('Canceladas'),
  todas('Todas');

  const OrdersScope(this.label);
  final String label;

  Set<OrderStatus>? get statuses => switch (this) {
        abiertas => OrderStatus.openStatuses.toSet(),
        sinTomar => {OrderStatus.recibida},
        recibida => {OrderStatus.recibida},
        enReparacion => {OrderStatus.enReparacion},
        lista => {OrderStatus.lista},
        entregada => {OrderStatus.entregada},
        cancelada => {OrderStatus.cancelada},
        todas => null,
      };
}

class OrdersFilter {
  const OrdersFilter({
    this.scope = OrdersScope.abiertas,
    this.search = '',
    this.technician,
  });

  final OrdersScope scope;
  final String search;

  /// Si no es null, solo se muestran las órdenes de este técnico.
  final Technician? technician;

  OrdersFilter copyWith({
    OrdersScope? scope,
    String? search,
    Technician? technician,
    bool clearTechnician = false,
  }) =>
      OrdersFilter(
        scope: scope ?? this.scope,
        search: search ?? this.search,
        technician: clearTechnician ? null : technician ?? this.technician,
      );
}

/// ViewModel de la lista de órdenes: guarda los filtros elegidos.
class OrdersFilterViewModel extends Notifier<OrdersFilter> {
  @override
  OrdersFilter build() => const OrdersFilter();

  void setScope(OrdersScope scope) => state = state.copyWith(scope: scope);

  void setSearch(String search) => state = state.copyWith(search: search);

  void setTechnician(Technician? technician) => state = technician == null
      ? state.copyWith(clearTechnician: true)
      : state.copyWith(technician: technician);

  /// Atajo usado desde el inicio: ver las órdenes de un técnico.
  void showTechnician(Technician technician) =>
      state = OrdersFilter(technician: technician);

  void showScope(OrdersScope scope) => state = OrdersFilter(scope: scope);
}

final ordersFilterProvider =
    NotifierProvider<OrdersFilterViewModel, OrdersFilter>(
  OrdersFilterViewModel.new,
);

final ordersListProvider = StreamProvider<List<OrderSummary>>((ref) {
  final filter = ref.watch(ordersFilterProvider);
  return ref.watch(ordersDaoProvider).watchOrders(
        statuses: filter.scope.statuses,
        onlyUntaken: filter.scope == OrdersScope.sinTomar,
        technicianId: filter.technician?.id,
        search: filter.search,
      );
});

// -----------------------------------------------------------------------------
// Detalle de una orden
// -----------------------------------------------------------------------------

final orderDetailProvider =
    StreamProvider.autoDispose.family<OrderDetail?, int>(
  (ref, orderId) => ref.watch(ordersDaoProvider).watchDetail(orderId),
);

/// ViewModel con las acciones sobre una orden. La vista solo llama a estos
/// métodos; las reglas (quién puede tomarla, stock, estados) viven en el DAO
/// y llegan como [WorkshopException] cuando algo no se permite.
class OrderActionsViewModel {
  OrderActionsViewModel(this._dao);

  final OrdersDao _dao;

  Future<void> take(int orderId, int technicianId) =>
      _dao.takeOrder(orderId, technicianId);

  Future<void> reassign(int orderId, int technicianId) =>
      _dao.reassign(orderId, technicianId);

  Future<void> release(int orderId) => _dao.releaseOrder(orderId);

  Future<void> markReady(int orderId) => _dao.markReady(orderId);

  Future<void> reopen(int orderId) => _dao.reopen(orderId);

  Future<void> deliver(int orderId) => _dao.deliver(orderId);

  Future<void> cancel(int orderId, String reason) =>
      _dao.cancel(orderId, reason: reason);

  Future<void> saveNotes(int orderId, String notes) =>
      _dao.updateNotes(orderId, notes);

  Future<void> addLabor(int orderId, String description, double cost) =>
      _dao.addLabor(orderId, description, cost);

  Future<void> removeLabor(int laborId) => _dao.removeLabor(laborId);

  /// Devuelve el repuesto actualizado para avisar si quedó por agotarse.
  Future<Part> addPart(int orderId, int partId, int quantity) =>
      _dao.addPart(orderId, partId, quantity);

  Future<void> removePart(int lineId) => _dao.removePartLine(lineId);
}

final orderActionsProvider = Provider<OrderActionsViewModel>(
  (ref) => OrderActionsViewModel(ref.watch(ordersDaoProvider)),
);
