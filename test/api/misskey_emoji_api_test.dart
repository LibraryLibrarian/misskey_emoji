import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_api_core/misskey_api_core.dart';
import 'package:misskey_emoji/src/api/misskey_emoji_api.dart';
import 'package:misskey_emoji/src/models/emoji_dto.dart';

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
  String? lastPath;
  String? lastMethod;
  RequestOptions? lastOptions;

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
    lastPath = path;
    lastMethod = method;
    lastOptions = options;

    if (shouldThrow) {
      throw Exception('Network error');
    }

    if (path == '/emojis') {
      return mockResponse as T;
    }

    throw UnimplementedError('Mock not implemented for $path');
  }
}

void main() {
  group('MisskeyEmojiApi', () {
    test('fetchAllで絵文字一覧を取得できる', () async {
      final httpClient = MockMisskeyHttpClient(
        mockResponse: {
          'emojis': [
            {
              'name': 'test_emoji',
              'aliases': ['alias1'],
              'url': 'https://example.com/emoji.png',
              'category': 'test',
              'localOnly': false,
              'isSensitive': false,
              'roleIdsThatCanBeUsedThisEmojiAsReaction': <String>[],
              'roleIdsThatCanNotBeUsedThisEmojiAsReaction': <String>[],
            },
          ],
        },
      );
      final api = MisskeyEmojiApi(httpClient);

      final records = await api.fetchAll();

      expect(records, hasLength(1));
      expect(records.first.name, equals('test_emoji'));
      expect(records.first.aliases, equals(['alias1']));
    });

    test('fetchAllが正しいパスとメソッドを使用する', () async {
      final httpClient = MockMisskeyHttpClient(
        mockResponse: {'emojis': <Map<String, dynamic>>[]},
      );
      final api = MisskeyEmojiApi(httpClient);

      await api.fetchAll();

      expect(httpClient.lastPath, equals('/emojis'));
      expect(httpClient.lastMethod, equals('GET'));
      expect(httpClient.lastOptions?.authRequired, isFalse);
      expect(httpClient.lastOptions?.idempotent, isTrue);
    });

    test('複数の絵文字を取得できる', () async {
      final httpClient = MockMisskeyHttpClient(
        mockResponse: {
          'emojis': [
            {
              'name': 'emoji1',
              'aliases': <String>[],
              'url': 'https://example.com/emoji1.png',
              'category': null,
              'localOnly': false,
              'isSensitive': false,
              'roleIdsThatCanBeUsedThisEmojiAsReaction': <String>[],
              'roleIdsThatCanNotBeUsedThisEmojiAsReaction': <String>[],
            },
            {
              'name': 'emoji2',
              'aliases': ['alias2'],
              'url': 'https://example.com/emoji2.gif',
              'category': 'category2',
              'localOnly': true,
              'isSensitive': true,
              'roleIdsThatCanBeUsedThisEmojiAsReaction': ['role1'],
              'roleIdsThatCanNotBeUsedThisEmojiAsReaction': ['role2'],
            },
          ],
        },
      );
      final api = MisskeyEmojiApi(httpClient);

      final records = await api.fetchAll();

      expect(records, hasLength(2));
      expect(records[0].name, equals('emoji1'));
      expect(records[1].name, equals('emoji2'));
      expect(records[1].localOnly, isTrue);
      expect(records[1].isSensitive, isTrue);
    });

    test('toRecordでDTOをレコードに変換できる', () {
      final httpClient = MockMisskeyHttpClient(mockResponse: {});
      final api = MisskeyEmojiApi(httpClient);

      const dto = EmojiDto(
        name: 'test_emoji',
        aliases: ['alias1', 'alias2'],
        url: 'https://example.com/emoji.png',
        category: 'test',
        localOnly: true,
        isSensitive: false,
        allowRoleIds: ['role1'],
        denyRoleIds: ['role2'],
      );

      final record = api.toRecord(dto);

      expect(record.name, equals('test_emoji'));
      expect(record.aliases, containsAll(['alias1', 'alias2']));
      expect(record.url, equals('https://example.com/emoji.png'));
      expect(record.category, equals('test'));
      expect(record.localOnly, isTrue);
      expect(record.isSensitive, isFalse);
      expect(record.allowRoleIds, equals(['role1']));
      expect(record.denyRoleIds, equals(['role2']));
    });

    test('toRecordでnull値がデフォルト値に変換される', () {
      final httpClient = MockMisskeyHttpClient(mockResponse: {});
      final api = MisskeyEmojiApi(httpClient);

      const dto = EmojiDto(
        name: 'test',
        aliases: [],
        url: 'https://example.com/emoji.png',
      );

      final record = api.toRecord(dto);

      expect(record.category, isNull);
      expect(record.localOnly, isFalse);
      expect(record.isSensitive, isFalse);
      expect(record.allowRoleIds, isEmpty);
      expect(record.denyRoleIds, isEmpty);
    });

    test('ショートコードが正規化される', () {
      final httpClient = MockMisskeyHttpClient(mockResponse: {});
      final api = MisskeyEmojiApi(httpClient);

      const dto = EmojiDto(
        name: ':Test_Emoji:',
        aliases: [':ALIAS1:', 'Alias2'],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
      );

      final record = api.toRecord(dto);

      expect(record.name, equals('test_emoji'));
      expect(record.aliases, containsAll(['alias1', 'alias2']));
    });

    test('エイリアスの重複が除去される', () {
      final httpClient = MockMisskeyHttpClient(mockResponse: {});
      final api = MisskeyEmojiApi(httpClient);

      const dto = EmojiDto(
        name: 'test',
        aliases: ['alias', 'ALIAS', ':alias:'],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
      );

      final record = api.toRecord(dto);

      // 正規化により重複が除去される
      expect(record.aliases.length, equals(1));
      expect(record.aliases.first, equals('alias'));
    });

    test('空の絵文字リストを処理できる', () async {
      final httpClient = MockMisskeyHttpClient(
        mockResponse: {'emojis': <Map<String, dynamic>>[]},
      );
      final api = MisskeyEmojiApi(httpClient);

      final records = await api.fetchAll();

      expect(records, isEmpty);
    });

    test('ネットワークエラー時に例外をスロー', () {
      final httpClient = MockMisskeyHttpClient(
        mockResponse: {},
        shouldThrow: true,
      );
      final api = MisskeyEmojiApi(httpClient);

      expect(
        api.fetchAll,
        throwsException,
      );
    });

    test('レスポンスがgrowable: falseのリスト', () async {
      final httpClient = MockMisskeyHttpClient(
        mockResponse: {
          'emojis': [
            {
              'name': 'test',
              'aliases': <String>[],
              'url': 'https://example.com/emoji.png',
              'category': null,
              'localOnly': false,
              'isSensitive': false,
              'roleIdsThatCanBeUsedThisEmojiAsReaction': <String>[],
              'roleIdsThatCanNotBeUsedThisEmojiAsReaction': <String>[],
            },
          ],
        },
      );
      final api = MisskeyEmojiApi(httpClient);

      final records = await api.fetchAll();

      expect(records, hasLength(1));
      // growable: false のリストなので追加できない
      expect(() => records.add(records.first), throwsUnsupportedError);
    });

    test('特殊文字を含む絵文字データを処理できる', () async {
      final httpClient = MockMisskeyHttpClient(
        mockResponse: {
          'emojis': [
            {
              'name': 'emoji_特殊文字_🎉',
              'aliases': ['alias_テスト'],
              'url': 'https://example.com/emoji-test.png?size=large',
              'category': 'カテゴリ',
              'localOnly': false,
              'isSensitive': false,
              'roleIdsThatCanBeUsedThisEmojiAsReaction': <String>[],
              'roleIdsThatCanNotBeUsedThisEmojiAsReaction': <String>[],
            },
          ],
        },
      );
      final api = MisskeyEmojiApi(httpClient);

      final records = await api.fetchAll();

      expect(records, hasLength(1));
      // 正規化されている
      expect(records.first.name, equals('emoji_特殊文字_🎉'));
    });

    test('大量の絵文字を処理できる', () async {
      final emojis = List.generate(
        1000,
        (i) => {
          'name': 'emoji_$i',
          'aliases': ['alias_$i'],
          'url': 'https://example.com/emoji_$i.png',
          'category': 'category_${i % 10}',
          'localOnly': i.isEven,
          'isSensitive': i % 3 == 0,
          'roleIdsThatCanBeUsedThisEmojiAsReaction': <String>[],
          'roleIdsThatCanNotBeUsedThisEmojiAsReaction': <String>[],
        },
      );

      final httpClient = MockMisskeyHttpClient(
        mockResponse: {'emojis': emojis},
      );
      final api = MisskeyEmojiApi(httpClient);

      final records = await api.fetchAll();

      expect(records, hasLength(1000));
    });
  });
}
