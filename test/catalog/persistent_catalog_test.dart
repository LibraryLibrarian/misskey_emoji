import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji/src/cache/emoji_store.dart';
import 'package:misskey_emoji/src/catalog/persistent_catalog.dart';
import 'package:misskey_emoji/src/models/emoji_record.dart';

import '../helpers/fake_emoji_source.dart';

const _records = [
  EmojiRecord(
    name: 'test_emoji',
    aliases: ['alias1', 'alias2'],
    url: 'https://example.com/emoji.png',
    category: 'test',
    localOnly: false,
    isSensitive: false,
    allowRoleIds: [],
  ),
  EmojiRecord(
    name: 'another_emoji',
    aliases: [],
    url: 'https://example.com/another.gif',
    category: 'test',
    localOnly: true,
    isSensitive: true,
    allowRoleIds: ['role1'],
  ),
];

class FakeEmojiStore implements EmojiStore {
  FakeEmojiStore({this.records = const [], this.syncedAt});

  List<EmojiRecord> records;
  DateTime? syncedAt;
  List<EmojiRecord> savedRecords = [];
  DateTime? savedSyncedAt;
  int loadCallCount = 0;
  int saveCallCount = 0;
  int disposeCallCount = 0;

  @override
  Future<EmojiSnapshot> load() async {
    loadCallCount++;
    return EmojiSnapshot(
      records: List<EmojiRecord>.from(records),
      syncedAt: syncedAt,
    );
  }

  @override
  Future<void> save(List<EmojiRecord> all, {required DateTime syncedAt}) async {
    saveCallCount++;
    savedRecords = _deduplicate(all);
    savedSyncedAt = syncedAt;
    records = List<EmojiRecord>.from(savedRecords);
    this.syncedAt = syncedAt;
  }

  @override
  Future<void> clear() async {
    records = [];
    syncedAt = null;
  }

  @override
  Future<int> count() async => records.length;

  @override
  Future<int?> sizeInBytes() async => null;

  @override
  Future<void> dispose() async {
    disposeCallCount++;
  }

  List<EmojiRecord> _deduplicate(List<EmojiRecord> all) {
    final recordsByName = <String, EmojiRecord>{};
    for (final record in all) {
      recordsByName.remove(record.name);
      recordsByName[record.name] = record;
    }
    return recordsByName.values.toList(growable: false);
  }
}

void main() {
  group('PersistentEmojiCatalog', () {
    late FakeEmojiSource source;
    late FakeEmojiStore store;
    late PersistentEmojiCatalog catalog;

    setUp(() {
      source = FakeEmojiSource(records: _records);
      store = FakeEmojiStore();
      catalog = PersistentEmojiCatalog(source: source, store: store);
    });

    test('初期状態では絵文字が空', () {
      expect(catalog.get('test_emoji'), isNull);
    });

    test('syncでストアをロードして最新データを保存する', () async {
      await catalog.sync(force: true);

      expect(store.loadCallCount, equals(1));
      expect(store.saveCallCount, equals(1));
      expect(store.savedRecords, equals(_records));
      expect(store.savedSyncedAt, isNotNull);
      expect(catalog.get('alias1')!.name, equals('test_emoji'));
    });

    test('ストアの既存データは取得成功後に最新データで置換される', () async {
      const cached = EmojiRecord(
        name: 'cached_emoji',
        aliases: [],
        url: 'https://example.com/cached.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
      );
      final cachedStore = FakeEmojiStore(records: [cached]);
      final testCatalog = PersistentEmojiCatalog(
        source: source,
        store: cachedStore,
      );

      await testCatalog.sync();

      expect(testCatalog.get('cached_emoji'), isNull);
      expect(testCatalog.get('test_emoji'), isNotNull);
    });

    test('取得エラー時はストアのキャッシュを保持して保存しない', () async {
      final errorSource = FakeEmojiSource(error: Exception('Network error'));
      final cachedStore = FakeEmojiStore(records: [_records.first]);
      final testCatalog = PersistentEmojiCatalog(
        source: errorSource,
        store: cachedStore,
      );

      await testCatalog.sync(force: true);

      expect(testCatalog.get('test_emoji'), isNotNull);
      expect(cachedStore.saveCallCount, isZero);
    });

    test('TTL内の再起動ではストアを復元して再取得しない', () async {
      final cachedStore = FakeEmojiStore(
        records: _records,
        syncedAt: DateTime.now(),
      );
      final testCatalog = PersistentEmojiCatalog(
        source: source,
        store: cachedStore,
      );

      await testCatalog.sync();

      expect(cachedStore.loadCallCount, equals(1));
      expect(source.callCount, isZero);
      expect(testCatalog.get('test_emoji'), isNotNull);
    });

    test('TTL超過後の再起動では再取得する', () async {
      final cachedStore = FakeEmojiStore(
        records: _records,
        syncedAt: DateTime.now().subtract(const Duration(minutes: 31)),
      );
      final testCatalog = PersistentEmojiCatalog(
        source: source,
        store: cachedStore,
      );

      await testCatalog.sync();

      expect(cachedStore.loadCallCount, equals(1));
      expect(source.callCount, equals(1));
    });

    test('force指定時はTTL内でも再取得する', () async {
      final cachedStore = FakeEmojiStore(
        records: _records,
        syncedAt: DateTime.now(),
      );
      final testCatalog = PersistentEmojiCatalog(
        source: source,
        store: cachedStore,
      );

      await testCatalog.sync(force: true);

      expect(cachedStore.loadCallCount, equals(1));
      expect(source.callCount, equals(1));
    });

    test('0件の同期結果もTTL内の再起動では再取得しない', () async {
      final emptySource = FakeEmojiSource();
      final firstCatalog = PersistentEmojiCatalog(
        source: emptySource,
        store: store,
      );

      await firstCatalog.sync(force: true);
      final restartedCatalog = PersistentEmojiCatalog(
        source: emptySource,
        store: store,
      );
      await restartedCatalog.sync();

      expect(store.records, isEmpty);
      expect(store.syncedAt, isNotNull);
      expect(emptySource.callCount, equals(1));
    });

    test('TTL内は再同期せずforceで再同期する', () async {
      await catalog.sync();
      await catalog.sync();
      expect(source.callCount, equals(1));

      await catalog.sync(force: true);
      expect(source.callCount, equals(2));
    });

    test('エラー時にクールダウンが適用される', () async {
      final errorSource = FakeEmojiSource(error: Exception('Network error'));
      final testCatalog = PersistentEmojiCatalog(
        source: errorSource,
        store: store,
      );

      await testCatalog.sync(force: true);
      await testCatalog.sync();
      expect(errorSource.callCount, equals(1));

      await testCatalog.sync(force: true);
      expect(errorSource.callCount, equals(2));
    });

    test('同時に複数のsyncを呼んでも1回だけ実行される', () async {
      await Future.wait([
        catalog.sync(force: true),
        catalog.sync(force: true),
        catalog.sync(force: true),
      ]);

      expect(source.callCount, equals(1));
      expect(store.saveCallCount, equals(1));
    });

    test('同一プロセス内ではストアからのロードは初回のみ', () async {
      await catalog.sync();
      await catalog.sync(force: true);
      await catalog.sync();

      expect(store.loadCallCount, equals(1));
    });

    test('ショートコードを正規化して取得できる', () async {
      await catalog.sync(force: true);

      expect(catalog.get(':TEST_EMOJI:'), isNotNull);
      expect(catalog.get('nonexistent'), isNull);
    });

    test('カスタムTTLが適用される', () async {
      final testCatalog = PersistentEmojiCatalog(
        source: source,
        store: store,
        ttl: const Duration(milliseconds: 100),
      );

      await testCatalog.sync();
      await testCatalog.sync();
      expect(source.callCount, equals(1));

      await Future<void>.delayed(const Duration(milliseconds: 150));
      await testCatalog.sync();
      expect(source.callCount, equals(2));
    });

    test('disposeでストアを1回だけdisposeする', () async {
      await catalog.dispose();
      await catalog.dispose();

      expect(store.disposeCallCount, equals(1));
    });

    test('ownsStoreがfalseの場合はdisposeでストアを破棄しない', () async {
      final sharedCatalog = PersistentEmojiCatalog(
        source: source,
        store: store,
        ownsStore: false,
      );

      await sharedCatalog.dispose();
      await sharedCatalog.dispose();

      expect(store.disposeCallCount, isZero);
    });

    test('dispose後のsyncはStateErrorを投げる', () async {
      await catalog.dispose();

      expect(catalog.sync, throwsA(isA<StateError>()));
    });

    test('disposeは進行中のsyncを待機する', () async {
      final completer = Completer<void>();
      final delayedSource = FakeEmojiSource(waitFor: completer.future);
      final testCatalog = PersistentEmojiCatalog(
        source: delayedSource,
        store: store,
      );

      final syncFuture = testCatalog.sync(force: true);
      final disposeFuture = testCatalog.dispose();
      final completedEarly = await Future.any<bool>([
        disposeFuture.then((_) => true),
        Future<void>.delayed(
          const Duration(milliseconds: 10),
        ).then((_) => false),
      ]);
      expect(completedEarly, isFalse);

      completer.complete();
      await syncFuture;
      await disposeFuture;
    });

    test('onSyncErrorコールバックに例外とスタックトレースを渡す', () async {
      Exception? capturedError;
      StackTrace? capturedStackTrace;
      final errorCatalog = PersistentEmojiCatalog(
        source: FakeEmojiSource(error: Exception('Network error')),
        store: store,
        onSyncError: (error, stackTrace) {
          capturedError = error;
          capturedStackTrace = stackTrace;
        },
      );

      await errorCatalog.sync(force: true);

      expect(capturedError.toString(), contains('Network error'));
      expect(capturedStackTrace, isNotNull);
    });
  });
}
