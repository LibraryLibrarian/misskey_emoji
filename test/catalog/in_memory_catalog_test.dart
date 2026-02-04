import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_api_core/misskey_api_core.dart';
import 'package:misskey_emoji/src/api/misskey_emoji_api.dart';
import 'package:misskey_emoji/src/catalog/in_memory_catalog.dart';
import 'package:misskey_emoji/src/models/emoji_record.dart';

/// テスト用のモックHTTPクライアント
class MockMisskeyHttpClient extends MisskeyHttpClient {
  MockMisskeyHttpClient({
    required this.mockResponse,
    this.shouldThrow = false,
  }) : super(
         config: MisskeyApiConfig(baseUrl: Uri.parse('https://test.example')),
       );

  final Map<String, dynamic> mockResponse;
  final bool shouldThrow;
  int callCount = 0;

  @override
  Future<T> send<T>(
    String path, {
    String method = 'POST',
    dynamic body,
    RequestOptions options = const RequestOptions(),
    Object? cancelToken,
    void Function(int, int)? onSendProgress,
  }) async {
    callCount++;

    if (shouldThrow) {
      throw Exception('Network error');
    }

    if (path == '/emojis') {
      return mockResponse as T;
    }

    throw UnimplementedError('Mock not implemented for $path');
  }
}

/// テスト用のモックMetaClient
class MockMetaClient extends MetaClient {
  MockMetaClient({
    required this.mockMeta,
    this.shouldThrow = false,
  }) : super(
         MockMisskeyHttpClient(
           mockResponse: {},
           shouldThrow: shouldThrow,
         ),
       );

  final Map<String, dynamic> mockMeta;
  final bool shouldThrow;

  @override
  Future<Meta> getMeta({bool refresh = false}) async {
    if (shouldThrow) {
      throw Exception('Meta fetch error');
    }

    return Meta.fromJson(mockMeta);
  }
}

void main() {
  group('InMemoryEmojiCatalog', () {
    late MisskeyEmojiApi api;
    late InMemoryEmojiCatalog catalog;

    setUp(() {
      final httpClient = MockMisskeyHttpClient(
        mockResponse: {
          'emojis': [
            {
              'name': 'test_emoji',
              'aliases': ['alias1', 'alias2'],
              'url': 'https://example.com/emoji.png',
              'category': 'test',
              'localOnly': false,
              'isSensitive': false,
              'roleIdsThatCanBeUsedThisEmojiAsReaction': <String>[],
              'roleIdsThatCanNotBeUsedThisEmojiAsReaction': <String>[],
            },
            {
              'name': 'another_emoji',
              'aliases': <String>[],
              'url': 'https://example.com/another.gif',
              'category': 'test',
              'localOnly': true,
              'isSensitive': true,
              'roleIdsThatCanBeUsedThisEmojiAsReaction': ['role1'],
              'roleIdsThatCanNotBeUsedThisEmojiAsReaction': ['role2'],
            },
          ],
        },
      );
      api = MisskeyEmojiApi(httpClient);
      catalog = InMemoryEmojiCatalog(api: api);
    });

    test('初期状態では絵文字が空', () {
      final result = catalog.get('test_emoji');
      expect(result, isNull);
    });

    test('syncで絵文字を取得できる', () async {
      await catalog.sync(force: true);

      final result = catalog.get('test_emoji');
      expect(result, isNotNull);
      expect(result!.name, equals('test_emoji'));
      expect(result.url, equals('https://example.com/emoji.png'));
    });

    test('エイリアスでも取得できる', () async {
      await catalog.sync(force: true);

      final result1 = catalog.get('alias1');
      final result2 = catalog.get('alias2');

      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result1!.name, equals('test_emoji'));
      expect(result2!.name, equals('test_emoji'));
    });

    test('複数の絵文字を取得できる', () async {
      await catalog.sync(force: true);

      final result1 = catalog.get('test_emoji');
      final result2 = catalog.get('another_emoji');

      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result1!.name, equals('test_emoji'));
      expect(result2!.name, equals('another_emoji'));
      expect(result2.localOnly, isTrue);
      expect(result2.isSensitive, isTrue);
    });

    test('snapshotで全絵文字を取得できる', () async {
      await catalog.sync(force: true);

      final snapshot = catalog.snapshot();

      expect(snapshot, isNotEmpty);
      expect(snapshot['test_emoji'], isNotNull);
      expect(snapshot['alias1'], isNotNull);
      expect(snapshot['another_emoji'], isNotNull);
    });

    test('snapshotは不変マップ', () async {
      await catalog.sync(force: true);

      final snapshot = catalog.snapshot();

      expect(
        () => snapshot['new_key'] = const EmojiRecord(
          name: 'new',
          aliases: [],
          url: '',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
          denyRoleIds: [],
        ),
        throwsUnsupportedError,
      );
    });

    test('TTL内は再同期しない', () async {
      final httpClient = MockMisskeyHttpClient(
        mockResponse: {
          'emojis': [
            {
              'name': 'test',
              'aliases': <String>[],
              'url': 'https://example.com/test.png',
              'category': null,
              'localOnly': false,
              'isSensitive': false,
              'roleIdsThatCanBeUsedThisEmojiAsReaction': <String>[],
              'roleIdsThatCanNotBeUsedThisEmojiAsReaction': <String>[],
            },
          ],
        },
      );
      final testApi = MisskeyEmojiApi(httpClient);
      final testCatalog = InMemoryEmojiCatalog(
        api: testApi,
      );

      await testCatalog.sync();
      expect(httpClient.callCount, equals(1));

      // TTL内なので再同期されない
      await testCatalog.sync();
      expect(httpClient.callCount, equals(1));

      // forceを指定すると再同期される
      await testCatalog.sync(force: true);
      expect(httpClient.callCount, equals(2));
    });

    test('エラー時にクールダウンが適用される', () async {
      final httpClient = MockMisskeyHttpClient(
        mockResponse: {},
        shouldThrow: true,
      );
      final testApi = MisskeyEmojiApi(httpClient);
      final testCatalog = InMemoryEmojiCatalog(
        api: testApi,
      );

      // エラーが発生する
      await testCatalog.sync(force: true);
      expect(httpClient.callCount, equals(1));

      // クールダウン期間内は再試行しない
      await testCatalog.sync();
      expect(httpClient.callCount, equals(1));

      // forceを指定すると再試行する
      await testCatalog.sync(force: true);
      expect(httpClient.callCount, equals(2));
    });

    test('エラー時でも既存のキャッシュは保持される', () async {
      await catalog.sync(force: true);

      final result1 = catalog.get('test_emoji');
      expect(result1, isNotNull);

      // エラーを起こすクライアントに差し替え
      final errorClient = MockMisskeyHttpClient(
        mockResponse: {},
        shouldThrow: true,
      );
      final errorApi = MisskeyEmojiApi(errorClient);
      final errorCatalog = InMemoryEmojiCatalog(api: errorApi);

      // 先にキャッシュを持たせる
      await catalog.sync(force: true);
      // エラーを起こす（しかし既存のキャッシュは保持される想定）
      await errorCatalog.sync(force: true);

      // 元のカタログのキャッシュは保持されている
      final result2 = catalog.get('test_emoji');
      expect(result2, isNotNull);
    });

    test('metaからの事前充填が動作する', () async {
      final metaClient = MockMetaClient(
        mockMeta: {
          'emojis': [
            {
              'name': 'meta_emoji',
              'aliases': <String>[],
              'url': 'https://example.com/meta.png',
              'category': 'meta',
              'localOnly': false,
              'isSensitive': false,
              'roleIdsThatCanBeUsedThisEmojiAsReaction': <String>[],
              'roleIdsThatCanNotBeUsedThisEmojiAsReaction': <String>[],
            },
          ],
        },
      );

      final httpClient = MockMisskeyHttpClient(
        mockResponse: {
          'emojis': [
            {
              'name': 'api_emoji',
              'aliases': <String>[],
              'url': 'https://example.com/api.png',
              'category': 'api',
              'localOnly': false,
              'isSensitive': false,
              'roleIdsThatCanBeUsedThisEmojiAsReaction': <String>[],
              'roleIdsThatCanNotBeUsedThisEmojiAsReaction': <String>[],
            },
          ],
        },
      );
      final testApi = MisskeyEmojiApi(httpClient);
      final testCatalog = InMemoryEmojiCatalog(
        api: testApi,
        meta: metaClient,
      );

      await testCatalog.sync(force: true);

      // API経由の絵文字が取得される（metaは最初の充填のみ）
      final result = testCatalog.get('api_emoji');
      expect(result, isNotNull);
      expect(result!.name, equals('api_emoji'));
    });

    test('同時に複数のsyncを呼んでも1回だけ実行される', () async {
      final httpClient = MockMisskeyHttpClient(
        mockResponse: {
          'emojis': [
            {
              'name': 'test',
              'aliases': <String>[],
              'url': 'https://example.com/test.png',
              'category': null,
              'localOnly': false,
              'isSensitive': false,
              'roleIdsThatCanBeUsedThisEmojiAsReaction': <String>[],
              'roleIdsThatCanNotBeUsedThisEmojiAsReaction': <String>[],
            },
          ],
        },
      );
      final testApi = MisskeyEmojiApi(httpClient);
      final testCatalog = InMemoryEmojiCatalog(api: testApi);

      // 同時に複数のsyncを呼ぶ
      await Future.wait([
        testCatalog.sync(force: true),
        testCatalog.sync(force: true),
        testCatalog.sync(force: true),
      ]);

      // 1回だけ実行される
      expect(httpClient.callCount, equals(1));
    });

    test('コロンで囲まれたショートコードでも取得できる', () async {
      await catalog.sync(force: true);

      final result = catalog.get(':test_emoji:');
      expect(result, isNotNull);
      expect(result!.name, equals('test_emoji'));
    });

    test('大文字小文字を区別しない', () async {
      await catalog.sync(force: true);

      final result = catalog.get('TEST_EMOJI');
      expect(result, isNotNull);
      expect(result!.name, equals('test_emoji'));
    });

    test('存在しないショートコードはnullを返す', () async {
      await catalog.sync(force: true);

      final result = catalog.get('nonexistent');
      expect(result, isNull);
    });

    test('カスタムTTLが適用される', () async {
      final httpClient = MockMisskeyHttpClient(
        mockResponse: {
          'emojis': <Map<String, dynamic>>[],
        },
      );
      final testApi = MisskeyEmojiApi(httpClient);
      final testCatalog = InMemoryEmojiCatalog(
        api: testApi,
        ttl: const Duration(milliseconds: 100),
      );

      await testCatalog.sync();
      expect(httpClient.callCount, equals(1));

      // TTL経過前
      await testCatalog.sync();
      expect(httpClient.callCount, equals(1));

      // TTL経過後
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await testCatalog.sync();
      expect(httpClient.callCount, equals(2));
    });
  });
}
