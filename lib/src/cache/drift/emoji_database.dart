import 'package:drift/drift.dart';

part 'emoji_database.g.dart';

/// 絵文字の各属性を保持するテーブル
@DataClassName('StoredEmojiRecord')
class EmojiRecords extends Table {
  TextColumn get name => text()();
  TextColumn get aliases => text()();
  TextColumn get category => text().nullable()();
  TextColumn get url => text()();
  BoolColumn get localOnly => boolean()();
  BoolColumn get isSensitive => boolean()();
  TextColumn get allowRoleIds => text()();

  @override
  Set<Column> get primaryKey => {name};
}

/// 同期時刻を保持する単一行のテーブル
class SyncMetadata extends Table {
  IntColumn get id => integer()();
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 接続方式に依存しない絵文字キャッシュのスキーマ
@DriftDatabase(tables: [EmojiRecords, SyncMetadata])
class EmojiDatabase extends _$EmojiDatabase {
  EmojiDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  // スキーマ変更時は必ずschemaVersionを増やすこと。
  // destructiveFallbackはバージョン差がある場合だけ発火し、初回のonCreateでは
  // 経由しない。同一バージョンでの破損復旧や過去に削除されたテーブルの掃除はしない。
  @override
  MigrationStrategy get migration => destructiveFallback;
}
