import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

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
  Future<EmojiSnapshot>? pendingLoad;
  Error? disposeError;
  Future<void>? pendingDispose;
  final disposeStarted = Completer<void>();

  @override
  Future<EmojiSnapshot> load() async {
    loadCallCount++;
    if (pendingLoad != null) return pendingLoad!;
    return EmojiSnapshot(
      records: List<EmojiRecord>.from(records, growable: false),
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
    if (!disposeStarted.isCompleted) disposeStarted.complete();
    await pendingDispose;
    if (disposeError != null) throw disposeError!;
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

class FailingOnceEmojiStore extends FakeEmojiStore {
  FailingOnceEmojiStore({super.records, super.syncedAt});

  bool _shouldFail = true;

  @override
  Future<EmojiSnapshot> load() async {
    loadCallCount++;
    if (_shouldFail) {
      _shouldFail = false;
      throw Exception('一時的なロードエラー');
    }
    return EmojiSnapshot(
      records: List<EmojiRecord>.from(records, growable: false),
      syncedAt: syncedAt,
    );
  }
}

class DelayedSaveEmojiStore extends FakeEmojiStore {
  DelayedSaveEmojiStore(this.saveDelay);

  final Duration saveDelay;

  @override
  Future<void> save(List<EmojiRecord> all, {required DateTime syncedAt}) async {
    await Future<void>.delayed(saveDelay);
    await super.save(all, syncedAt: syncedAt);
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

    test('保存待機より短いTTLでも保存した同期成功時刻をTTL判定に使う', () async {
      const saveDelay = Duration(milliseconds: 100);
      final delayedStore = DelayedSaveEmojiStore(saveDelay);
      final testCatalog = PersistentEmojiCatalog(
        source: source,
        store: delayedStore,
        ttl: const Duration(milliseconds: 25),
      );

      await testCatalog.sync();
      expect(delayedStore.savedSyncedAt, isNotNull);

      await testCatalog.sync();

      expect(source.callCount, equals(2));
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

    test('name重複時も保存前後でショートコードの解決結果が一致する', () async {
      const oldRecord = EmojiRecord(
        name: 'a',
        aliases: ['old'],
        url: 'https://example.com/old.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
      );
      const newRecord = EmojiRecord(
        name: 'a',
        aliases: [],
        url: 'https://example.com/new.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
      );
      final duplicateSource = FakeEmojiSource(records: [oldRecord, newRecord]);
      final firstCatalog = PersistentEmojiCatalog(
        source: duplicateSource,
        store: store,
      );

      await firstCatalog.sync(force: true);

      expect(store.savedRecords, equals([newRecord]));
      expect(firstCatalog.get('a')?.url, equals(newRecord.url));
      expect(firstCatalog.get('old'), isNull);

      final restartedSource = FakeEmojiSource();
      final restartedCatalog = PersistentEmojiCatalog(
        source: restartedSource,
        store: store,
      );
      await restartedCatalog.sync();

      expect(restartedSource.callCount, isZero);
      expect(restartedCatalog.get('a')?.url, equals(newRecord.url));
      expect(restartedCatalog.get('old'), isNull);
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

    test('ロード失敗後の同期ではストアから再度復元を試みる', () async {
      final retryStore = FailingOnceEmojiStore(
        records: _records,
        syncedAt: DateTime.now(),
      );
      final testCatalog = PersistentEmojiCatalog(
        source: source,
        store: retryStore,
      );

      await expectLater(testCatalog.sync(), throwsA(isA<Exception>()));
      await testCatalog.sync();

      expect(retryStore.loadCallCount, equals(2));
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

    for (final ownsStore in [true, false]) {
      test('同期失敗時も所有権に従ってストアを破棄する（ownsStore: $ownsStore）', () async {
        final load = Completer<EmojiSnapshot>();
        final syncError = Exception('ロード失敗');
        store.pendingLoad = load.future;
        final testCatalog = PersistentEmojiCatalog(
          source: source,
          store: store,
          ownsStore: ownsStore,
        );

        final syncResult = expectLater(
          testCatalog.sync(),
          throwsA(same(syncError)),
        );
        final disposeResult = expectLater(
          testCatalog.dispose(),
          throwsA(same(syncError)),
        );
        expect(store.disposeCallCount, isZero);

        load.completeError(syncError);
        await syncResult;
        await disposeResult;

        expect(store.disposeCallCount, ownsStore ? 1 : 0);
      });
    }

    test('同期とストア破棄の両方が失敗した場合は破棄エラーを優先する', () async {
      final load = Completer<EmojiSnapshot>();
      final syncError = Exception('ロード失敗');
      final disposeError = StateError('ストア破棄失敗');
      store
        ..pendingLoad = load.future
        ..disposeError = disposeError;

      final syncResult = expectLater(catalog.sync(), throwsA(same(syncError)));
      final disposeResult = expectLater(
        catalog.dispose(),
        throwsA(same(disposeError)),
      );
      load.completeError(syncError);
      await syncResult;
      await disposeResult;

      expect(store.disposeCallCount, equals(1));
    });

    test('ストア破棄だけが失敗した場合も破棄エラーを送出する', () async {
      final disposeError = StateError('ストア破棄失敗');
      store.disposeError = disposeError;

      await expectLater(catalog.dispose(), throwsA(same(disposeError)));

      expect(store.disposeCallCount, equals(1));
    });

    test('dispose後のsyncはStateErrorを投げる', () async {
      await catalog.dispose();

      expect(catalog.sync, throwsA(isA<StateError>()));
    });

    for (final ownsStore in [true, false]) {
      test('並行disposeは同期と所有ストアの破棄を最後まで待つ（ownsStore: $ownsStore）', () async {
        final fetch = Completer<void>();
        final close = Completer<void>();
        store.pendingDispose = close.future;
        final testCatalog = PersistentEmojiCatalog(
          source: FakeEmojiSource(records: _records, waitFor: fetch.future),
          store: store,
          ownsStore: ownsStore,
        );
        final syncFuture = testCatalog.sync(force: true);
        final first = testCatalog.dispose();
        final second = testCatalog.dispose();
        expect(second, same(first));
        var completed = 0;
        final results = [
          first.then((_) => completed++),
          second.then((_) => completed++),
        ];

        await Future<void>.delayed(Duration.zero);
        expect(completed, isZero);
        expect(store.disposeCallCount, isZero);
        expect(store.saveCallCount, isZero);
        await expectLater(testCatalog.sync(), throwsA(isA<StateError>()));

        fetch.complete();
        await syncFuture;
        expect(store.savedRecords, equals(_records));
        expect(store.saveCallCount, equals(1));
        if (ownsStore) {
          await store.disposeStarted.future;
          expect(completed, isZero);
          expect(testCatalog.dispose(), same(first));
        }
        close.complete();
        await Future.wait(results);

        expect(completed, equals(2));
        expect(store.disposeCallCount, ownsStore ? 1 : 0);
        await testCatalog.dispose();
        expect(store.disposeCallCount, ownsStore ? 1 : 0);
      });
    }

    test('並行disposeと失敗後のdisposeは同じ破棄エラーを共有する', () async {
      final load = Completer<EmojiSnapshot>();
      final syncError = Exception('ロード失敗');
      final disposeError = StateError('ストア破棄失敗');
      store
        ..pendingLoad = load.future
        ..disposeError = disposeError;
      final syncResult = expectLater(catalog.sync(), throwsA(same(syncError)));
      final first = catalog.dispose();
      final second = catalog.dispose();
      expect(second, same(first));
      final firstResult = expectLater(first, throwsA(same(disposeError)));
      final secondResult = expectLater(second, throwsA(same(disposeError)));

      load.completeError(syncError);
      await Future.wait([syncResult, firstResult, secondResult]);
      expect(catalog.dispose(), same(first));
      await expectLater(catalog.dispose(), throwsA(same(disposeError)));
      expect(store.disposeCallCount, equals(1));
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
