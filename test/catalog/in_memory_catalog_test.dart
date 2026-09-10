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

void main() {
  group('InMemoryEmojiCatalog', () {
    late FakeEmojiSource source;
    late InMemoryEmojiCatalog catalog;

    setUp(() {
      source = FakeEmojiSource(records: _records);
      catalog = InMemoryEmojiCatalog(source: source);
    });

    test('初期状態では絵文字が空', () {
      expect(catalog.get('test_emoji'), isNull);
    });

    test('syncで絵文字を取得できる', () async {
      await catalog.sync(force: true);

      final result = catalog.get('test_emoji');
      expect(result, isNotNull);
      expect(result!.url, equals('https://example.com/emoji.png'));
      expect(catalog.get('another_emoji')!.localOnly, isTrue);
    });

    test('エイリアスでも取得できる', () async {
      await catalog.sync(force: true);

      expect(catalog.get('alias1')!.name, equals('test_emoji'));
      expect(catalog.get('alias2')!.name, equals('test_emoji'));
    });

    test('name重複時も取得結果を重複除去しない', () async {
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
      final duplicateCatalog = InMemoryEmojiCatalog(
        source: FakeEmojiSource(records: [oldRecord, newRecord]),
      );

      await duplicateCatalog.sync(force: true);

      expect(duplicateCatalog.get('a')?.url, equals(newRecord.url));
      expect(duplicateCatalog.get('old')?.url, equals(oldRecord.url));
    });

    test('snapshotは全キーを含む不変マップ', () async {
      await catalog.sync(force: true);

      final snapshot = catalog.snapshot();
      expect(snapshot.keys, containsAll(['test_emoji', 'alias1', 'alias2']));
      expect(
        () => snapshot['new'] = _records.first,
        throwsUnsupportedError,
      );
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
      final errorCatalog = InMemoryEmojiCatalog(source: errorSource);

      await errorCatalog.sync(force: true);
      await errorCatalog.sync();
      expect(errorSource.callCount, equals(1));

      await errorCatalog.sync(force: true);
      expect(errorSource.callCount, equals(2));
    });

    test('エラー時でも既存のキャッシュは保持される', () async {
      await catalog.sync(force: true);
      source = FakeEmojiSource(error: Exception('Network error'));
      final failingCatalog = InMemoryEmojiCatalog(source: source)
        ..byKey = catalog.snapshot();

      await failingCatalog.sync(force: true);

      expect(failingCatalog.get('test_emoji'), isNotNull);
    });

    test('同時に複数のsyncを呼んでも1回だけ実行される', () async {
      await Future.wait([
        catalog.sync(force: true),
        catalog.sync(force: true),
        catalog.sync(force: true),
      ]);

      expect(source.callCount, equals(1));
    });

    test('ショートコードを正規化して取得できる', () async {
      await catalog.sync(force: true);

      expect(catalog.get(':TEST_EMOJI:'), isNotNull);
      expect(catalog.get('nonexistent'), isNull);
    });

    test('カスタムTTLが適用される', () async {
      final testCatalog = InMemoryEmojiCatalog(
        source: source,
        ttl: const Duration(milliseconds: 100),
      );

      await testCatalog.sync();
      await testCatalog.sync();
      expect(source.callCount, equals(1));

      await Future<void>.delayed(const Duration(milliseconds: 150));
      await testCatalog.sync();
      expect(source.callCount, equals(2));
    });

    test('onSyncErrorコールバックに例外とスタックトレースを渡す', () async {
      Exception? capturedError;
      StackTrace? capturedStackTrace;
      final errorCatalog = InMemoryEmojiCatalog(
        source: FakeEmojiSource(error: Exception('Network error')),
        onSyncError: (error, stackTrace) {
          capturedError = error;
          capturedStackTrace = stackTrace;
        },
      );

      await errorCatalog.sync(force: true);

      expect(capturedError.toString(), contains('Network error'));
      expect(capturedStackTrace, isNotNull);
    });

    test('並行disposeは同じFutureを共有して進行中の同期を待つ', () async {
      final fetch = Completer<void>();
      final testCatalog = InMemoryEmojiCatalog(
        source: FakeEmojiSource(records: _records, waitFor: fetch.future),
      );
      final syncFuture = testCatalog.sync();
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
      await expectLater(testCatalog.sync(), throwsA(isA<StateError>()));

      fetch.complete();
      await syncFuture;
      await Future.wait(results);
      expect(completed, equals(2));
      expect(testCatalog.get('test_emoji'), isNotNull);
      expect(testCatalog.dispose(), same(first));
      await testCatalog.dispose();
    });

    test('dispose後のsyncはStateErrorを投げる', () async {
      await catalog.dispose();

      expect(catalog.sync, throwsA(isA<StateError>()));
    });
  });
}
