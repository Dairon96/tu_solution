import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../models/workshop_exception.dart';
import '../providers/database_providers.dart';

class InventoryFilter {
  const InventoryFilter({this.search = '', this.onlyLow = false});

  final String search;
  final bool onlyLow;
}

class InventoryFilterViewModel extends Notifier<InventoryFilter> {
  @override
  InventoryFilter build() => const InventoryFilter();

  void setSearch(String search) =>
      state = InventoryFilter(search: search, onlyLow: state.onlyLow);

  void setOnlyLow(bool onlyLow) =>
      state = InventoryFilter(search: state.search, onlyLow: onlyLow);
}

final inventoryFilterProvider =
    NotifierProvider<InventoryFilterViewModel, InventoryFilter>(
  InventoryFilterViewModel.new,
);

final partsListProvider = StreamProvider<List<Part>>((ref) {
  final filter = ref.watch(inventoryFilterProvider);
  return ref
      .watch(partsDaoProvider)
      .watchAll(search: filter.search, onlyLow: filter.onlyLow);
});

/// Todos los repuestos (para elegir cuál usar en una orden).
final allPartsProvider = StreamProvider.autoDispose<List<Part>>(
  (ref) => ref.watch(partsDaoProvider).watchAll(),
);

/// Datos del formulario de repuesto.
class PartFormData {
  const PartFormData({
    required this.code,
    required this.name,
    required this.price,
    required this.stock,
    required this.minStock,
  });

  final String code;
  final String name;
  final double price;
  final int stock;
  final int minStock;
}

class InventoryViewModel {
  InventoryViewModel(this._ref);

  final Ref _ref;

  /// Crea ([id] null) o actualiza un repuesto.
  Future<void> save(PartFormData data, {int? id}) async {
    if (data.price < 0 || data.stock < 0 || data.minStock < 0) {
      throw const WorkshopException('Los valores no pueden ser negativos.');
    }
    final dao = _ref.read(partsDaoProvider);
    if (await dao.codeExists(data.code, exceptId: id)) {
      throw WorkshopException('Ya existe un repuesto con código ${data.code}.');
    }
    final companion = PartsCompanion(
      code: Value(data.code.trim().toUpperCase()),
      name: Value(data.name.trim()),
      price: Value(data.price),
      stock: Value(data.stock),
      minStock: Value(data.minStock),
    );
    if (id == null) {
      await dao.create(companion);
    } else {
      await dao.updatePart(id, companion);
    }
  }

  /// Registra una entrada de mercancía.
  Future<void> addStock(int partId, int quantity) {
    if (quantity <= 0) {
      throw const WorkshopException('La cantidad debe ser mayor que cero.');
    }
    return _ref.read(partsDaoProvider).addStock(partId, quantity);
  }
}

final inventoryViewModelProvider =
    Provider<InventoryViewModel>(InventoryViewModel.new);
