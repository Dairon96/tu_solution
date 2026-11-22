import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/daos/orders_dao.dart';
import '../data/database/app_database.dart';
import '../providers/database_providers.dart';

/// Estado del formulario de recepción de un equipo.
class ReceptionState {
  const ReceptionState({
    this.saving = false,
    this.existingCustomer,
    this.customerDevices = const [],
    this.selectedDevice,
  });

  final bool saving;

  /// Cliente encontrado por su teléfono (null = cliente nuevo).
  final Customer? existingCustomer;

  /// Equipos que ya trajo ese cliente antes.
  final List<Device> customerDevices;

  /// Equipo anterior elegido (null = equipo nuevo).
  final Device? selectedDevice;

  ReceptionState copyWith({
    bool? saving,
    Customer? existingCustomer,
    bool clearCustomer = false,
    List<Device>? customerDevices,
    Device? selectedDevice,
    bool clearDevice = false,
  }) =>
      ReceptionState(
        saving: saving ?? this.saving,
        existingCustomer:
            clearCustomer ? null : existingCustomer ?? this.existingCustomer,
        customerDevices: customerDevices ?? this.customerDevices,
        selectedDevice:
            clearDevice ? null : selectedDevice ?? this.selectedDevice,
      );
}

class ReceptionViewModel extends Notifier<ReceptionState> {
  @override
  ReceptionState build() => const ReceptionState();

  /// Busca si el teléfono ya pertenece a un cliente para reutilizarlo.
  Future<Customer?> lookupPhone(String phone) async {
    final customersDao = ref.read(customersDaoProvider);
    final customer = phone.trim().length < 3
        ? null
        : await customersDao.findByPhone(phone);
    if (customer == null) {
      state = state.copyWith(
        clearCustomer: true,
        customerDevices: const [],
        clearDevice: true,
      );
      return null;
    }
    final devices = await customersDao.devicesOf(customer.id);
    state = state.copyWith(
      existingCustomer: customer,
      customerDevices: devices,
      clearDevice: true,
    );
    return customer;
  }

  /// Busca un equipo por número de serie (puede ser de otro cliente).
  Future<Device?> lookupSerial(String serial) {
    if (serial.trim().isEmpty) return Future.value(null);
    return ref.read(customersDaoProvider).findDeviceBySerial(serial);
  }

  void selectDevice(Device? device) => state = device == null
      ? state.copyWith(clearDevice: true)
      : state.copyWith(selectedDevice: device);

  /// Registra la orden y devuelve su id.
  Future<int> submit(ReceptionData data) async {
    state = state.copyWith(saving: true);
    try {
      return await ref.read(ordersDaoProvider).receiveDevice(data);
    } finally {
      state = state.copyWith(saving: false);
    }
  }
}

final receptionProvider =
    NotifierProvider.autoDispose<ReceptionViewModel, ReceptionState>(
  ReceptionViewModel.new,
);
