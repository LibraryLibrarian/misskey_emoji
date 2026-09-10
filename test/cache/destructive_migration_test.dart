import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/migration_database.dart' show MigrationDatabaseV1;
import '../helpers/migration_database_v2.dart' show MigrationDatabaseV2;

void main() {
  late Directory directory;
  final databases = <GeneratedDatabase>[];
  const syncedAt = '2026-09-10T12:34:56.789123Z';

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('emoji_migration_');
  });
  tearDown(() async {
    for (final database in databases) {
      await database.close();
    }
    databases.clear();
    await directory.delete(recursive: true);
  });

  GeneratedDatabase open(int version) {
    final connection = DatabaseConnection(
      NativeDatabase(File('${directory.path}/cache.sqlite')),
      closeStreamsSynchronously: true,
    );
    final database = version == 1
        ? MigrationDatabaseV1(connection)
        : MigrationDatabaseV2(connection);
    databases.add(database);
    return database;
  }

  Future<void> close(GeneratedDatabase database) async {
    await database.close();
    databases.remove(database);
  }

  Future<void> write(GeneratedDatabase database, String name) async {
    await database.transaction(() async {
      await database.customStatement(
        'INSERT INTO migration_records (name) VALUES (?)',
        [name],
      );
      await database.customStatement(
        'INSERT INTO migration_metadata (id, synced_at) VALUES (1, ?)',
        [syncedAt],
      );
    });
  }

  Future<void> expectContents(GeneratedDatabase database, String? name) async {
    final records = await database
        .customSelect(
          'SELECT name FROM migration_records',
        )
        .get();
    final metadata = await database
        .customSelect(
          'SELECT id, synced_at FROM migration_metadata',
        )
        .get();
    if (name == null) {
      expect(records, isEmpty);
      expect(metadata, isEmpty);
    } else {
      expect(records.single.read<String>('name'), name);
      expect(metadata.single.read<int>('id'), 1);
      expect(metadata.single.read<String>('synced_at'), syncedAt);
    }
    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.read<int>('user_version'), database.schemaVersion);
  }

  for (final (from, to) in [(1, 2), (2, 1)]) {
    test('v$fromからv$toへの移行で全テーブルを破棄し再び読み書きできる', () async {
      final original = open(from);
      await write(original, '移行前');
      await expectContents(original, '移行前');
      await close(original);

      final migrated = open(to);
      await expectContents(migrated, null);
      await write(migrated, '移行後');
      await expectContents(migrated, '移行後');
      await close(migrated);
      await expectContents(open(to), '移行後');
    });
  }

  test('初回作成で両テーブルを作成しその後の書き込みを永続化する', () async {
    expect(File('${directory.path}/cache.sqlite').existsSync(), isFalse);
    final database = open(1);
    await expectContents(database, null);
    await write(database, '初回保存');
    await expectContents(database, '初回保存');
    await close(database);
    await expectContents(open(1), '初回保存');
  });

  test('同一バージョンで再オープンしても両テーブルのデータを保持する', () async {
    final database = open(2);
    await write(database, '保持対象');
    await close(database);
    final reopened = open(2);
    await expectContents(reopened, '保持対象');
    await close(reopened);
    await expectContents(open(2), '保持対象');
  });
}
