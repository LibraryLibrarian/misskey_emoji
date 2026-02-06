import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji/src/catalog/catalog.dart';
import 'package:misskey_emoji/src/models/emoji_record.dart';
import 'package:misskey_emoji/src/resolver/resolver.dart';

/// テスト用のモックカタログ
class MockEmojiCatalog implements EmojiCatalog {
  MockEmojiCatalog({
    this.mockRecords = const {},
    this.syncCalled = false,
  });

  final Map<String, EmojiRecord> mockRecords;
  bool syncCalled;
  int syncCallCount = 0;

  @override
  EmojiRecord? get(String shortcode) => mockRecords[shortcode];

  @override
  Map<String, EmojiRecord> snapshot() => Map.unmodifiable(mockRecords);

  @override
  Future<void> sync({bool force = false}) async {
    syncCalled = true;
    syncCallCount++;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('EmojiImage', () {
    test('基本的なEmojiImageの作成', () {
      final image = EmojiImage(
        url: Uri.parse('https://example.com/emoji.png'),
        animated: false,
        isSensitive: false,
      );

      expect(image.url.toString(), equals('https://example.com/emoji.png'));
      expect(image.animated, isFalse);
      expect(image.isSensitive, isFalse);
    });

    test('アニメーション・センシティブなEmojiImageの作成', () {
      final image = EmojiImage(
        url: Uri.parse('https://example.com/emoji.gif'),
        animated: true,
        isSensitive: true,
      );

      expect(image.animated, isTrue);
      expect(image.isSensitive, isTrue);
    });
  });

  group('MisskeyEmojiResolver', () {
    test('存在する絵文字を解決できる', () async {
      const record = EmojiRecord(
        name: 'test_emoji',
        aliases: [],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      final catalog = MockEmojiCatalog(
        mockRecords: {'test_emoji': record},
      );
      final resolver = MisskeyEmojiResolver(catalog);

      final result = await resolver.resolve('test_emoji');

      expect(result, isNotNull);
      expect(result!.url.toString(), equals('https://example.com/emoji.png'));
      expect(result.animated, isFalse);
      expect(result.isSensitive, isFalse);
    });

    test('存在しない絵文字はnullを返す', () async {
      final catalog = MockEmojiCatalog(mockRecords: {});
      final resolver = MisskeyEmojiResolver(catalog);

      final result = await resolver.resolve('nonexistent');

      expect(result, isNull);
    });

    test('コロンで囲まれたショートコードも解決できる', () async {
      const record = EmojiRecord(
        name: 'test_emoji',
        aliases: [],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      // normalizeShortcode(':test_emoji:') は 'test_emoji' になる
      final catalog = MockEmojiCatalog(
        mockRecords: {'test_emoji': record},
      );
      final resolver = MisskeyEmojiResolver(catalog);

      final result = await resolver.resolve('test_emoji');

      expect(result, isNotNull);
      expect(result!.url.toString(), equals('https://example.com/emoji.png'));
    });

    test('アニメーション絵文字の情報が正しく取得できる', () async {
      const record = EmojiRecord(
        name: 'animated',
        aliases: [],
        url: 'https://example.com/emoji.gif',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      final catalog = MockEmojiCatalog(
        mockRecords: {'animated': record},
      );
      final resolver = MisskeyEmojiResolver(catalog);

      final result = await resolver.resolve('animated');

      expect(result, isNotNull);
      expect(result!.animated, isTrue);
    });

    test('センシティブ絵文字の情報が正しく取得できる', () async {
      const record = EmojiRecord(
        name: 'sensitive',
        aliases: [],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: true,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      final catalog = MockEmojiCatalog(
        mockRecords: {'sensitive': record},
      );
      final resolver = MisskeyEmojiResolver(catalog);

      final result = await resolver.resolve('sensitive');

      expect(result, isNotNull);
      expect(result!.isSensitive, isTrue);
    });

    test('キャッシュミス時に自動的に同期を行う', () async {
      const record = EmojiRecord(
        name: 'test',
        aliases: [],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      // mockRecordsを変更可能な状態で作成
      final mockRecords = <String, EmojiRecord>{};
      final catalog = MockEmojiCatalog(mockRecords: mockRecords);
      final resolver = MisskeyEmojiResolver(catalog);

      // 最初は存在しない
      final result1 = await resolver.resolve('test');
      expect(result1, isNull);
      expect(catalog.syncCalled, isTrue);
      expect(catalog.syncCallCount, equals(1));

      // 同期後に絵文字を追加
      mockRecords['test'] = record;

      // 再度解決すると取得できる
      final result2 = await resolver.resolve('test');
      expect(result2, isNotNull);
    });

    test('関数オブジェクトとして呼び出せる', () async {
      const record = EmojiRecord(
        name: 'test',
        aliases: [],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      final catalog = MockEmojiCatalog(
        mockRecords: {'test': record},
      );
      final resolver = MisskeyEmojiResolver(catalog);

      // call()メソッドを使用
      final result = await resolver('test');

      expect(result, isNotNull);
      expect(result!.url.toString(), equals('https://example.com/emoji.png'));
    });

    test('dispose後にresolveするとStateErrorを投げる', () async {
      final catalog = MockEmojiCatalog(mockRecords: {});
      final resolver = MisskeyEmojiResolver(catalog);

      await resolver.dispose();

      expect(() => resolver.resolve('test'), throwsA(isA<StateError>()));
      expect(() => resolver.call('test'), throwsA(isA<StateError>()));
    });

    test('disposeは複数回呼べる', () async {
      final catalog = MockEmojiCatalog(mockRecords: {});
      final resolver = MisskeyEmojiResolver(catalog);

      await resolver.dispose();
      await resolver.dispose(); // 2回目も安全

      expect(() => resolver.resolve('test'), throwsA(isA<StateError>()));
    });

    test('URLが正しくパースされる', () async {
      const record = EmojiRecord(
        name: 'test',
        aliases: [],
        url: 'https://cdn.example.com/emojis/test.png?size=large',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      final catalog = MockEmojiCatalog(
        mockRecords: {'test': record},
      );
      final resolver = MisskeyEmojiResolver(catalog);

      final result = await resolver.resolve('test');

      expect(result, isNotNull);
      expect(result!.url.scheme, equals('https'));
      expect(result.url.host, equals('cdn.example.com'));
      expect(result.url.path, equals('/emojis/test.png'));
      expect(result.url.queryParameters['size'], equals('large'));
    });

    test('複数の絵文字を連続して解決できる', () async {
      const record1 = EmojiRecord(
        name: 'emoji1',
        aliases: [],
        url: 'https://example.com/emoji1.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      const record2 = EmojiRecord(
        name: 'emoji2',
        aliases: [],
        url: 'https://example.com/emoji2.gif',
        localOnly: false,
        isSensitive: true,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      final catalog = MockEmojiCatalog(
        mockRecords: {
          'emoji1': record1,
          'emoji2': record2,
        },
      );
      final resolver = MisskeyEmojiResolver(catalog);

      final result1 = await resolver.resolve('emoji1');
      final result2 = await resolver.resolve('emoji2');

      expect(result1, isNotNull);
      expect(result1!.url.toString(), equals('https://example.com/emoji1.png'));
      expect(result1.animated, isFalse);
      expect(result1.isSensitive, isFalse);

      expect(result2, isNotNull);
      expect(result2!.url.toString(), equals('https://example.com/emoji2.gif'));
      expect(result2.animated, isTrue);
      expect(result2.isSensitive, isTrue);
    });
  });
}
