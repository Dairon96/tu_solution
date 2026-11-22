import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables.dart';

part 'parts_dao.g.dart';

@DriftAccessor(tables: [Parts])
class PartsDao extends DatabaseAccessor<AppDatabase> with _$PartsDaoMixin {
  PartsDao(super.attachedDatabase);

  /// Inventario completo, con búsqueda opcional por nombre o código.
  Stream<List<Part>> watchAll({String search = '', bool onlyLow = false}) {
    final query = select(parts);
    final term = search.trim();
    if (term.isNotEmpty) {
      query.where((p) => p.name.like('%$term%') | p.code.like('%$term%'));
    }
    if (onlyLow) {
      query.where((p) => p.stock.isSmallerOrEqual(p.minStock));
    }
    query.orderBy([(p) => OrderingTerm.asc(p.name)]);
    return query.watch();
  }

  /// Repuestos por agotarse: existencias <= mínimo.
  Stream<List<Part>> watchLowStock() => (select(parts)
        ..where((p) => p.stock.isSmallerOrEqual(p.minStock))
        ..orderBy([(p) => OrderingTerm.asc(p.stock)]))
      .watch();

  Stream<Part?> watchById(int id) =>
      (select(parts)..where((p) => p.id.equals(id))).watchSingleOrNull();

  Future<int> create(PartsCompanion part) => into(parts).insert(part);

  Future<void> updatePart(int id, PartsCompanion part) =>
      (update(parts)..where((p) => p.id.equals(id))).write(part);

  /// Entrada de mercancía al almacén.
  Future<void> addStock(int id, int quantity) {
    return customUpdate(
      'UPDATE parts SET stock = stock + ? WHERE id = ?',
      variables: [Variable.withInt(quantity), Variable.withInt(id)],
      updates: {parts},
    );
  }

  Future<bool> codeExists(String code, {int? exceptId}) async {
    final query = select(parts)..where((p) => p.code.equals(code.trim()));
    if (exceptId != null) query.where((p) => p.id.equals(exceptId).not());
    return (await query.get()).isNotEmpty;
  }
}
