import 'package:drift/drift.dart';

import 'migration_database.dart' show MigrationMetadata, MigrationRecords;

part 'migration_database_v2.g.dart';

/// 同じテーブルでもバージョン差だけで破棄されることを検証する第2世代
///
/// 生成されるテーブル型の名前が重複するため、世代ごとにライブラリを分ける。
@DriftDatabase(tables: [MigrationRecords, MigrationMetadata])
class MigrationDatabaseV2 extends _$MigrationDatabaseV2 {
  MigrationDatabaseV2(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => destructiveFallback;
}
