import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji/src/util/server_db.dart';

void main() {
  group('serverKeyFromBaseUrl', () {
    test('基本的なHTTPS URLからキーを生成', () {
      final key = serverKeyFromBaseUrl(Uri.parse('https://misskey.io'));
      expect(key, equals('https_misskey_io'));
    });

    test('HTTP URLからキーを生成', () {
      final key = serverKeyFromBaseUrl(Uri.parse('http://example.com'));
      expect(key, equals('http_example_com'));
    });

    test('ポート番号付きURLからキーを生成', () {
      final key = serverKeyFromBaseUrl(Uri.parse('https://example.com:3000'));
      expect(key, equals('https_example_com_3000'));
    });

    test('デフォルトポート（443）は含まれない', () {
      final key = serverKeyFromBaseUrl(Uri.parse('https://example.com'));
      expect(key, equals('https_example_com'));
      expect(key.contains('443'), isFalse);
    });

    test('デフォルトポート（80）は含まれない', () {
      final key = serverKeyFromBaseUrl(Uri.parse('http://example.com'));
      expect(key, equals('http_example_com'));
      expect(key.contains('80'), isFalse);
    });

    test('大文字が小文字に変換される', () {
      final key = serverKeyFromBaseUrl(Uri.parse('https://MISSKEY.IO'));
      expect(key, equals('https_misskey_io'));
    });

    test('パスは含まれない', () {
      final key = serverKeyFromBaseUrl(
        Uri.parse('https://example.com/api/path'),
      );
      expect(key, equals('https_example_com'));
      expect(key.contains('api'), isFalse);
      expect(key.contains('path'), isFalse);
    });

    test('クエリパラメータは含まれない', () {
      final key = serverKeyFromBaseUrl(
        Uri.parse('https://example.com?param=value'),
      );
      expect(key, equals('https_example_com'));
      expect(key.contains('param'), isFalse);
      expect(key.contains('value'), isFalse);
    });

    test('特殊文字がアンダースコアに置き換えられる', () {
      final key = serverKeyFromBaseUrl(
        Uri.parse('https://mis-key.example.com'),
      );
      expect(key, equals('https_mis_key_example_com'));
    });

    test('連続するアンダースコアが単一のアンダースコアに置き換えられる', () {
      final key = serverKeyFromBaseUrl(
        Uri.parse('https://mis--key..example..com'),
      );
      expect(key, equals('https_mis_key_example_com'));
      expect(key.contains('__'), isFalse);
    });

    test('サブドメインを含むURL', () {
      final key = serverKeyFromBaseUrl(
        Uri.parse('https://sub.domain.example.com'),
      );
      expect(key, equals('https_sub_domain_example_com'));
    });

    test('IPアドレス形式のURL', () {
      final key = serverKeyFromBaseUrl(Uri.parse('https://192.168.1.1'));
      expect(key, equals('https_192_168_1_1'));
    });

    test('IPv6アドレス形式のURL', () {
      final key = serverKeyFromBaseUrl(Uri.parse('https://[::1]'));
      // 特殊文字が変換される
      expect(key, matches(RegExp(r'^https_[a-z0-9_]+$')));
    });

    test('ローカルホストのURL', () {
      final key = serverKeyFromBaseUrl(Uri.parse('http://localhost'));
      expect(key, equals('http_localhost'));
    });

    test('ローカルホストにポート番号付き', () {
      final key = serverKeyFromBaseUrl(Uri.parse('http://localhost:8080'));
      expect(key, equals('http_localhost_8080'));
    });

    test('結果が英数字とアンダースコアのみで構成される', () {
      final urls = [
        'https://misskey.io',
        'https://example.com:3000',
        'https://sub.domain.example.com',
        'https://192.168.1.1',
      ];

      for (final url in urls) {
        final key = serverKeyFromBaseUrl(Uri.parse(url));
        expect(key, matches(RegExp(r'^[a-z0-9_]+$')));
      }
    });

    test('異なるURLは異なるキーを生成する', () {
      final key1 = serverKeyFromBaseUrl(Uri.parse('https://misskey.io'));
      final key2 = serverKeyFromBaseUrl(Uri.parse('https://example.com'));
      final key3 = serverKeyFromBaseUrl(Uri.parse('http://misskey.io'));

      expect(key1, isNot(equals(key2)));
      expect(key1, isNot(equals(key3)));
      expect(key2, isNot(equals(key3)));
    });

    test('同じURLは同じキーを生成する', () {
      final key1 = serverKeyFromBaseUrl(Uri.parse('https://misskey.io'));
      final key2 = serverKeyFromBaseUrl(Uri.parse('https://misskey.io'));

      expect(key1, equals(key2));
    });

    test('トレイリングスラッシュの有無は影響しない', () {
      final key1 = serverKeyFromBaseUrl(Uri.parse('https://misskey.io'));
      final key2 = serverKeyFromBaseUrl(Uri.parse('https://misskey.io/'));

      expect(key1, equals(key2));
    });
  });

  group('openEmojiIsarForServer', () {
    test('生成されるDB名がサーバーキーを含む', () {
      final baseUrl = Uri.parse('https://misskey.io');
      final expectedKey = serverKeyFromBaseUrl(baseUrl);

      // DB名の形式を確認
      expect(
        'misskey_emoji_$expectedKey',
        matches(RegExp(r'^misskey_emoji_[a-z0-9_]+$')),
      );
    });

    test('異なるサーバーには異なるDB名が生成される', () {
      final key1 = serverKeyFromBaseUrl(Uri.parse('https://misskey.io'));
      final key2 = serverKeyFromBaseUrl(Uri.parse('https://example.com'));

      final dbName1 = 'misskey_emoji_$key1';
      final dbName2 = 'misskey_emoji_$key2';

      expect(dbName1, isNot(equals(dbName2)));
    });

    test('同じサーバーには同じDB名が生成される', () {
      final key1 = serverKeyFromBaseUrl(Uri.parse('https://misskey.io'));
      final key2 = serverKeyFromBaseUrl(Uri.parse('https://misskey.io'));

      final dbName1 = 'misskey_emoji_$key1';
      final dbName2 = 'misskey_emoji_$key2';

      expect(dbName1, equals(dbName2));
    });
  });
}
