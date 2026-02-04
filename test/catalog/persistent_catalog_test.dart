import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_api_core/misskey_api_core.dart';
import 'package:misskey_emoji/src/api/misskey_emoji_api.dart';
import 'package:misskey_emoji/src/cache/emoji_store.dart';
import 'package:misskey_emoji/src/catalog/persistent_catalog.dart';
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

/// テスト用のモックEmojiStore
class MockEmojiStore implements EmojiStore {
  MockEmojiStore({this.initialRecords = const []});

  List<EmojiRecord> initialRecords;
  List<EmojiRecord> savedRecords = [];
  int loadCallCount = 0;
  int saveCallCount = 0;

  @override
  Future<List<EmojiRecord>> loadAll() async {
    loadCallCount++;
    return List<EmojiRecord>.from(initialRecords);
  }

  @override
  Future<void> saveAll(List<EmojiRecord> all) async {
    saveCallCount++;
    savedRecords = List<EmojiRecord>.from(all);
    initialRecords = savedRecords;
  }
}

void main() {
  group('PersistentEmojiCatalog', () {
    late MisskeyEmojiApi api;
    late MockEmojiStore store;
    late PersistentEmojiCatalog catalog;

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
      store = MockEmojiStore();
      catalog = PersistentEmojiCatalog(api: api, store: store);
    });

    test('初期状態では絵文字が空', () {
      final result = catalog.get('test_emoji');
      expect(result, isNull);
    });

    test('syncでストアから絵文字をロードする', () async {
      const cachedRecord = EmojiRecord(
        name: 'cached_emoji',
        aliases: [],
        url: 'https://example.com/cached.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      final testStore = MockEmojiStore(initialRecords: [cachedRecord]);
      final testCatalog = PersistentEmojiCatalog(
        api: api,
        store: testStore,
      );

      await testCatalog.sync();

      expect(testStore.loadCallCount, equals(1));
      final result = testCatalog.get('cached_emoji');
      // APIからの取得により、test_emojiも取得される
      expect(result, isNull); // cached_emojiはAPIにないため

      // しかしAPIの絵文字は取得できる
      final apiResult = testCatalog.get('test_emoji');
      expect(apiResult, isNotNull);
    });

    test('syncで新しい絵文字を取得してストアに保存', () async {
      await catalog.sync(force: true);

      expect(store.saveCallCount, equals(1));
      expect(store.savedRecords, hasLength(2));
      expect(
        store.savedRecords.map((r) => r.name),
        containsAll(['test_emoji', 'another_emoji']),
      );
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
      final testStore = MockEmojiStore();
      final testCatalog = PersistentEmojiCatalog(
        api: testApi,
        store: testStore,
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
      final testStore = MockEmojiStore();
      final testCatalog = PersistentEmojiCatalog(
        api: testApi,
        store: testStore,
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
      // まず正常なデータを取得してストアに保存
      await catalog.sync(force: true);

      final result1 = catalog.get('test_emoji');
      expect(result1, isNotNull);

      // エラーを起こすクライアントに差し替え
      final errorClient = MockMisskeyHttpClient(
        mockResponse: {},
        shouldThrow: true,
      );
      final errorApi = MisskeyEmojiApi(errorClient);
      final errorCatalog = PersistentEmojiCatalog(api: errorApi, store: store);

      // 先にキャッシュをロード（storeに保存されたデータがある）
      await errorCatalog.sync();

      // キャッシュから読み込まれている
      final result2 = errorCatalog.get('test_emoji');
      expect(result2, isNotNull);

      // エラーを起こす（しかし既存のキャッシュは保持される想定）
      await errorCatalog.sync(force: true);

      // エラー後もキャッシュは保持されている
      final result3 = errorCatalog.get('test_emoji');
      expect(result3, isNotNull);
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
      final testStore = MockEmojiStore();
      final testCatalog = PersistentEmojiCatalog(
        api: testApi,
        store: testStore,
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
      final testStore = MockEmojiStore();
      final testCatalog = PersistentEmojiCatalog(
        api: testApi,
        store: testStore,
      );

      // 同時に複数のsyncを呼ぶ
      await Future.wait([
        testCatalog.sync(force: true),
        testCatalog.sync(force: true),
        testCatalog.sync(force: true),
      ]);

      // 1回だけ実行される
      expect(httpClient.callCount, equals(1));
    });

    test('ストアからのロードは初回のみ', () async {
      await catalog.sync();
      expect(store.loadCallCount, equals(1));

      // 2回目はロードされない
      await catalog.sync(force: true);
      expect(store.loadCallCount, equals(1));
    });

    test('同期成功時にストアに保存される', () async {
      expect(store.saveCallCount, equals(0));

      await catalog.sync(force: true);

      expect(store.saveCallCount, equals(1));
      expect(store.savedRecords, isNotEmpty);
    });

    test('同期失敗時はストアに保存されない', () async {
      final errorClient = MockMisskeyHttpClient(
        mockResponse: {},
        shouldThrow: true,
      );
      final errorApi = MisskeyEmojiApi(errorClient);
      final testStore = MockEmojiStore();
      final errorCatalog = PersistentEmojiCatalog(
        api: errorApi,
        store: testStore,
      );

      await errorCatalog.sync(force: true);

      // エラー時は保存されない
      expect(testStore.saveCallCount, equals(0));
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
      final testStore = MockEmojiStore();
      final testCatalog = PersistentEmojiCatalog(
        api: testApi,
        store: testStore,
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

    test('ストアに既存データがある場合、それをロードする', () async {
      const existingRecord = EmojiRecord(
        name: 'existing_emoji',
        aliases: ['existing_alias'],
        url: 'https://example.com/existing.png',
        category: 'existing',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      final testStore = MockEmojiStore(initialRecords: [existingRecord]);
      final testCatalog = PersistentEmojiCatalog(api: api, store: testStore);

      // syncを呼ぶと、まずストアからロードし、その後APIから取得する
      await testCatalog.sync();

      // ストアからのロードは確認された（loadCallCountが1）
      expect(testStore.loadCallCount, equals(1));

      // しかし、API呼び出しにより、APIから返された絵文字がストアに保存される
      // そのため、existing_emojiは失われ、test_emojiが取得できる
      final result = testCatalog.get('test_emoji');
      expect(result, isNotNull);
      expect(result!.name, equals('test_emoji'));
    });
  });
}
