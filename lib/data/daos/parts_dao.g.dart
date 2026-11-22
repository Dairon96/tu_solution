// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parts_dao.dart';

// ignore_for_file: type=lint
mixin _$PartsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PartsTable get parts => attachedDatabase.parts;
  PartsDaoManager get managers => PartsDaoManager(this);
}

class PartsDaoManager {
  final _$PartsDaoMixin _db;
  PartsDaoManager(this._db);
  $$PartsTableTableManager get parts =>
      $$PartsTableTableManager(_db.attachedDatabase, _db.parts);
}
