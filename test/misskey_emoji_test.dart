import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

void main() {
  group('misskey_emoji パッケージ', () {
    test('公開APIがエクスポートされている', () {
      // 主要なクラスと型がエクスポートされている
      expect(EmojiRecord, isNotNull);
      expect(MisskeyEmojiResolver, isNotNull);
      expect(InMemoryEmojiCatalog, isNotNull);
      expect(PersistentEmojiCatalog, isNotNull);
      expect(EmojiCatalog, isNotNull);
      expect(EmojiStore, isNotNull);
      expect(IsarEmojiStore, isNotNull);
      expect(EmojiSource, isNotNull);
      expect(MisskeyClientEmojiSource, isNotNull);
      expect(EmojiSearch, isNotNull);
    });

    test('検索関連のクラスがエクスポートされている', () {
      expect(EmojiSearchOptions, isNotNull);
      expect(EmojiSearchResult, isNotNull);
      expect(EmojiSearchMode, isNotNull);
    });

    test('ユーティリティ関数がエクスポートされている', () {
      expect(normalizeShortcode, isNotNull);
      expect(serverKeyFromBaseUrl, isNotNull);
      expect(openEmojiIsarForServer, isNotNull);
    });

    test('ショートコード正規化が正しく動作する', () {
      final normalized = normalizeShortcode(':Test_Emoji:');
      expect(normalized, equals('test_emoji'));
    });

    test('EmojiRecordが正しく作成できる', () {
      const record = EmojiRecord(
        name: 'test',
        aliases: ['alias'],
        url: 'https://example.com/emoji.png',
        category: 'test',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
      );

      expect(record.name, equals('test'));
      expect(record.animated, isFalse);
    });

    test('EmojiSearchOptionsがデフォルト値を持つ', () {
      const options = EmojiSearchOptions();

      expect(options.limit, equals(50));
      expect(options.mode, equals(EmojiSearchMode.prefix));
      expect(options.includeAliases, isTrue);
    });

    test('検索モードの列挙型が定義されている', () {
      expect(EmojiSearchMode.prefix, isNotNull);
      expect(EmojiSearchMode.contains, isNotNull);
    });

    test('serverKeyFromBaseUrlが正しく動作する', () {
      final key = serverKeyFromBaseUrl(Uri.parse('https://misskey.io'));
      expect(key, equals('https_misskey_io'));
    });
  });
}
