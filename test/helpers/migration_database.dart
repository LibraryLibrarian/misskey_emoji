import 'package:drift/drift.dart';

part 'migration_database.g.dart';

/// バージョン変更時のレコード破棄を検証する最小テーブル
class MigrationRecords extends Table {
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {name};
}

/// レコードと独立して同期時刻の破棄を検証する最小テーブル
class MigrationMetadata extends Table {
  IntColumn get id => integer()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 本番スキーマに依存しない第1世代のテスト用DB
@DriftDatabase(tables: [MigrationRecords, MigrationMetadata])
class MigrationDatabaseV1 extends _$MigrationDatabaseV1 {
  MigrationDatabaseV1(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => destructiveFallback;
}
