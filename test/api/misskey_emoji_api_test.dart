import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_emoji/src/source/emoji_source.dart';

class _TestServer {
  _TestServer._(this.server, this.response);

  final HttpServer server;
  final Map<String, dynamic> response;
  String? lastPath;
  String? lastMethod;

  Uri get baseUrl => Uri.parse('http://${server.address.host}:${server.port}');

  static Future<_TestServer> start(Map<String, dynamic> response) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _TestServer._(server, response);
    server.listen(fixture._handle);
    return fixture;
  }

  Future<void> _handle(HttpRequest request) async {
    lastPath = request.uri.path;
    lastMethod = request.method;
    await utf8.decoder.bind(request).join();
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(response));
    await request.response.close();
  }

  Future<void> close() => server.close(force: true);
}

void main() {
  group('MisskeyClientEmojiSource', () {
    late _TestServer server;

    tearDown(() async {
      await server.close();
    });

    test('MisskeyCustomEmojiをEmojiRecordへ変換する', () async {
      server = await _TestServer.start({
        'emojis': [
          {
            'name': ':Test_Emoji:',
            'aliases': [':ALIAS:', 'Alias', 'second'],
            'url': 'https://example.com/emoji.gif',
            'category': 'test',
            'localOnly': true,
            'isSensitive': true,
            'roleIdsThatCanBeUsedThisEmojiAsReaction': ['role1'],
          },
        ],
      });
      final source = MisskeyClientEmojiSource(
        MisskeyClient(
          config: MisskeyClientConfig(baseUrl: server.baseUrl, maxRetries: 1),
        ),
      );

      final records = await source.fetchAll();

      expect(records, hasLength(1));
      expect(records.first.name, equals('test_emoji'));
      expect(records.first.aliases, equals(['alias', 'second']));
      expect(records.first.url, equals('https://example.com/emoji.gif'));
      expect(records.first.category, equals('test'));
      expect(records.first.localOnly, isTrue);
      expect(records.first.isSensitive, isTrue);
      expect(records.first.allowRoleIds, equals(['role1']));
      expect(server.lastPath, equals('/api/emojis'));
      expect(server.lastMethod, equals('POST'));
    });

    test('nullableフィールドに既存と同じデフォルトを適用する', () async {
      server = await _TestServer.start({
        'emojis': [
          {
            'name': 'minimal',
            'url': 'https://example.com/minimal.png',
          },
        ],
      });
      final source = MisskeyClientEmojiSource(
        MisskeyClient(
          config: MisskeyClientConfig(baseUrl: server.baseUrl, maxRetries: 1),
        ),
      );

      final records = await source.fetchAll();
      final record = records.single;

      expect(record.aliases, isEmpty);
      expect(record.category, isNull);
      expect(record.localOnly, isFalse);
      expect(record.isSensitive, isFalse);
      expect(record.allowRoleIds, isEmpty);
      expect(() => records.add(record), throwsUnsupportedError);
    });

    test('空の絵文字一覧を処理できる', () async {
      server = await _TestServer.start({'emojis': <Map<String, dynamic>>[]});
      final source = MisskeyClientEmojiSource(
        MisskeyClient(
          config: MisskeyClientConfig(baseUrl: server.baseUrl, maxRetries: 1),
        ),
      );

      expect(await source.fetchAll(), isEmpty);
    });
  });
}
