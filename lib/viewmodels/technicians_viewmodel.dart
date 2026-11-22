import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../models/workshop_exception.dart';
import '../providers/database_providers.dart';

final techniciansProvider = StreamProvider<List<Technician>>(
  (ref) => ref.watch(techniciansDaoProvider).watchAll(),
);

final activeTechniciansProvider = StreamProvider<List<Technician>>(
  (ref) => ref.watch(techniciansDaoProvider).watchAll(onlyActive: true),
);

class TechniciansViewModel {
  TechniciansViewModel(this._ref);

  final Ref _ref;

  Future<void> create(String name) {
    if (name.trim().isEmpty) {
      throw const WorkshopException('Escribe el nombre del técnico.');
    }
    return _ref.read(techniciansDaoProvider).create(name.trim());
  }

  Future<void> rename(int id, String name) {
    if (name.trim().isEmpty) {
      throw const WorkshopException('Escribe el nombre del técnico.');
    }
    return _ref.read(techniciansDaoProvider).rename(id, name.trim());
  }

  Future<void> setActive(int id, bool active) =>
      _ref.read(techniciansDaoProvider).setActive(id, active);
}

final techniciansViewModelProvider =
    Provider<TechniciansViewModel>(TechniciansViewModel.new);
