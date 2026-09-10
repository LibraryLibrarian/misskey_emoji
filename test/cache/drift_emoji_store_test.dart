import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji/src/cache/drift/connection/native.dart';
import 'package:misskey_emoji/src/cache/drift/drift_emoji_store.dart';
import 'package:misskey_emoji/src/cache/drift/emoji_database.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

const _first = EmojiRecord(
  name: 'z',
  aliases: ['別名', '"\\'],
  category: '分類',
  url: 'https://example.com/z.png',
  localOnly: true,
  isSensitive: true,
  allowRoleIds: ['role1', 'role2'],
);
const _second = EmojiRecord(
  name: 'a',
  aliases: [],
  url: 'https://example.com/a.png',
  localOnly: false,
  isSensitive: false,
  allowRoleIds: [],
);
const _last = EmojiRecord(
  name: 'z',
  aliases: ['新しい別名'],
  url: 'https://example.com/new.png',
  localOnly: false,
  isSensitive: false,
  allowRoleIds: [],
);

class _FailingCloseDatabase extends EmojiDatabase {
  _FailingCloseDatabase() : super(NativeDatabase.memory());

  int closeCount = 0;

  @override
  Future<void> close() async {
    closeCount++;
    await super.close();
    throw StateError('終了処理の失敗');
  }
}

List<Object?> _values(EmojiRecord record) => [
  record.name,
  record.aliases,
  record.category,
  record.url,
  record.localOnly,
  record.isSensitive,
  record.allowRoleIds,
];

void main() {
  final syncedAt = DateTime.utc(2026, 9, 10, 12, 34, 56, 789, 123);

  group('DriftEmojiStore', () {
    late EmojiDatabase database;
    late DriftEmojiStore store;

    setUp(() {
      database = EmojiDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      store = DriftEmojiStore(database);
    });
    tearDown(() => store.dispose());

    test('未保存と空の同期結果を区別しclearで時刻も削除する', () async {
      final initial = await store.load();
      expect(initial.records, isEmpty);
      expect(initial.syncedAt, isNull);
      expect(await store.count(), isZero);
      await store.save([_first], syncedAt: syncedAt);
      await store.save([], syncedAt: syncedAt);
      final empty = await store.load();
      expect(empty.records, isEmpty);
      expect(empty.syncedAt, syncedAt);
      expect(await store.count(), isZero);
      await store.clear();
      final cleared = await store.load();
      expect(cleared.records, isEmpty);
      expect(cleared.syncedAt, isNull);
      expect(await store.sizeInBytes(), isNull);
    });

    test('全属性とマイクロ秒の同期時刻を入力順で復元する', () async {
      await store.save([_first, _second], syncedAt: syncedAt);
      // ORDER BYの削除を、現在のSQLiteの既定走査順に依存せず検出する。
      await database.customStatement('PRAGMA reverse_unordered_selects = ON');
      final snapshot = await store.load();
      expect(snapshot.syncedAt, syncedAt);
      expect(snapshot.records.map((record) => record.name), ['z', 'a']);
      final first = snapshot.records.first;
      expect(first.aliases, _first.aliases);
      expect(first.category, _first.category);
      expect(first.url, _first.url);
      expect(first.localOnly, isTrue);
      expect(first.isSensitive, isTrue);
      expect(first.allowRoleIds, _first.allowRoleIds);
      final second = snapshot.records.last;
      expect(second.category, isNull);
      expect(second.aliases, isEmpty);
      expect(second.allowRoleIds, isEmpty);
      expect(second.localOnly, isFalse);
      expect(second.isSensitive, isFalse);
    });

    test('単一レコードを保存し既存の一覧を全置換する', () async {
      await store.save([_first, _second], syncedAt: syncedAt);
      final next = syncedAt.add(const Duration(minutes: 1));
      await store.save([_last], syncedAt: next);
      final snapshot = await store.load();
      expect(_values(snapshot.records.single), _values(_last));
      expect(snapshot.syncedAt, next);
      expect(await store.count(), 1);
    });

    test('大量のレコードを入力順のまま保存して読み込める', () async {
      final records = List.generate(
        15000,
        (index) => EmojiRecord(
          name: '絵文字_$index',
          aliases: ['別名_$index'],
          url: 'https://example.com/$index.png',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
        ),
      );
      await store.save(records, syncedAt: syncedAt);
      final snapshot = await store.load();
      expect(snapshot.records.map(_values), records.map(_values));
      expect(await store.count(), records.length);
      expect(snapshot.syncedAt, syncedAt);
    });

    test('空と非空の読み込み結果は長さを変更できない', () async {
      final empty = (await store.load()).records;
      expect(() => empty.add(_first), throwsUnsupportedError);
      await store.save([_first], syncedAt: syncedAt);
      final records = (await store.load()).records;
      expect(() => records.add(_second), throwsUnsupportedError);
      expect(() => records.removeLast(), throwsUnsupportedError);
    });

    test('重複を後勝ちで除去し最後の出現位置へ移す', () async {
      await store.save([_first, _second, _last], syncedAt: syncedAt);
      final snapshot = await store.load();
      expect(snapshot.records.map((record) => record.name), ['a', 'z']);
      expect(snapshot.records.last.url, _last.url);
      expect(snapshot.records.last.aliases, _last.aliases);
      expect(await store.count(), 2);
    });

    test('保存途中の失敗でレコードと時刻を両方ロールバックする', () async {
      await store.save([_first], syncedAt: syncedAt);
      // 全レコードの置換が済んだ後、メタデータ挿入だけを失敗させる。
      await database.customStatement('''
CREATE TRIGGER fail_metadata BEFORE INSERT ON sync_metadata
BEGIN SELECT RAISE(ABORT, '同期時刻の保存失敗'); END
''');
      await expectLater(
        store.save([_second], syncedAt: syncedAt.add(const Duration(days: 1))),
        throwsA(isA<Exception>()),
      );
      final snapshot = await store.load();
      expect(snapshot.records.single.name, _first.name);
      expect(snapshot.syncedAt, syncedAt);
    });

    test('並行する保存とロードでもレコードと同期時刻が対応する', () async {
      await store.save([_first], syncedAt: syncedAt);
      final next = syncedAt.add(const Duration(days: 1));
      final saving = store.save([_second], syncedAt: next);
      final loading = store.load();
      await saving;
      final snapshot = await loading;
      expect(
        (snapshot.records.single.name, snapshot.syncedAt),
        anyOf((_first.name, syncedAt), (_second.name, next)),
      );
    });

    test('disposeは冪等で破棄後の全操作を拒否する', () async {
      await store.load();
      await Future.wait([store.dispose(), store.dispose()]);
      await store.dispose();
      expect(store.load, throwsStateError);
      await expectLater(store.save([], syncedAt: syncedAt), throwsStateError);
      await expectLater(store.clear(), throwsStateError);
      await expectLater(store.count(), throwsStateError);
      await expectLater(store.sizeInBytes(), throwsStateError);
    });
  });

  test('終了失敗時も登録解除を一度だけ呼ぶ', () async {
    final database = _FailingCloseDatabase();
    var released = 0;
    final store = DriftEmojiStore(database, onDisposed: () => released++);
    await store.load();
    await expectLater(store.dispose(), throwsStateError);
    await expectLater(store.dispose(), throwsStateError);
    expect(database.closeCount, 1);
    expect(released, 1);
    expect(store.load, throwsStateError);
  });

  test('実ファイルのWALとSHMを含む論理サイズを返す', () async {
    final directory = await Directory.systemTemp.createTemp('emoji_size_');
    final path = '${directory.path}/cache.sqlite';
    final database = EmojiDatabase(
      await openConnection(
        directory: directory.path,
        databaseName: 'cache',
      ),
    );
    final store = DriftEmojiStore(
      database,
      readSizeInBytes: () => databaseSizeInBytes(path),
    );
    try {
      await database.customStatement('PRAGMA journal_mode = WAL');
      await store.save([_first], syncedAt: syncedAt);
      final lengths = await Future.wait([
        File(path).length(),
        File('$path-wal').length(),
        File('$path-shm').length(),
      ]);
      expect(lengths.every((length) => length > 0), isTrue);
      expect(await store.sizeInBytes(), lengths.reduce((a, b) => a + b));
    } finally {
      await store.dispose();
      await directory.delete(recursive: true);
    }
  });

  test('補助ファイルなしは許容しI/Oエラーは伝播する', () async {
    final directory = await Directory.systemTemp.createTemp(
      'emoji_size_error_',
    );
    final path = '${directory.path}/cache.sqlite';
    try {
      await File(path).writeAsBytes([1, 2, 3]);
      expect(await databaseSizeInBytes(path), 3);
      await Directory('$path-wal').create();
      await expectLater(
        databaseSizeInBytes(path),
        throwsA(isA<FileSystemException>()),
      );
      await File(path).delete();
      await expectLater(
        databaseSizeInBytes(path),
        throwsA(isA<FileSystemException>()),
      );
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
