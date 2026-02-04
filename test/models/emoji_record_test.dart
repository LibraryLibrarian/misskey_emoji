import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji/src/models/emoji_record.dart';

void main() {
  group('EmojiRecord', () {
    test('基本的なレコードの作成', () {
      const record = EmojiRecord(
        name: 'test_emoji',
        aliases: ['alias1', 'alias2'],
        url: 'https://example.com/emoji.png',
        category: 'test',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      expect(record.name, equals('test_emoji'));
      expect(record.aliases, equals(['alias1', 'alias2']));
      expect(record.url, equals('https://example.com/emoji.png'));
      expect(record.category, equals('test'));
      expect(record.localOnly, isFalse);
      expect(record.isSensitive, isFalse);
      expect(record.allowRoleIds, isEmpty);
      expect(record.denyRoleIds, isEmpty);
    });

    test('カテゴリなしのレコード作成', () {
      const record = EmojiRecord(
        name: 'test',
        aliases: [],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      expect(record.category, isNull);
    });

    test('ロール制限付きレコードの作成', () {
      const record = EmojiRecord(
        name: 'premium_emoji',
        aliases: [],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: ['role1', 'role2'],
        denyRoleIds: ['role3'],
      );

      expect(record.allowRoleIds, equals(['role1', 'role2']));
      expect(record.denyRoleIds, equals(['role3']));
    });

    group('animated getter', () {
      test('GIF画像はアニメーションとして判定', () {
        const record = EmojiRecord(
          name: 'test',
          aliases: [],
          url: 'https://example.com/emoji.gif',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
          denyRoleIds: [],
        );

        expect(record.animated, isTrue);
      });

      test('APNG画像はアニメーションとして判定', () {
        const record = EmojiRecord(
          name: 'test',
          aliases: [],
          url: 'https://example.com/emoji.apng',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
          denyRoleIds: [],
        );

        expect(record.animated, isTrue);
      });

      test('WebP画像はアニメーションとして判定', () {
        const record = EmojiRecord(
          name: 'test',
          aliases: [],
          url: 'https://example.com/emoji.webp',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
          denyRoleIds: [],
        );

        expect(record.animated, isTrue);
      });

      test('PNG画像は非アニメーションとして判定', () {
        const record = EmojiRecord(
          name: 'test',
          aliases: [],
          url: 'https://example.com/emoji.png',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
          denyRoleIds: [],
        );

        expect(record.animated, isFalse);
      });

      test('JPG画像は非アニメーションとして判定', () {
        const record = EmojiRecord(
          name: 'test',
          aliases: [],
          url: 'https://example.com/emoji.jpg',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
          denyRoleIds: [],
        );

        expect(record.animated, isFalse);
      });

      test('大文字の拡張子でも正しく判定', () {
        const recordGif = EmojiRecord(
          name: 'test',
          aliases: [],
          url: 'https://example.com/emoji.GIF',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
          denyRoleIds: [],
        );
        const recordPng = EmojiRecord(
          name: 'test',
          aliases: [],
          url: 'https://example.com/emoji.PNG',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
          denyRoleIds: [],
        );

        expect(recordGif.animated, isTrue);
        expect(recordPng.animated, isFalse);
      });

      test('クエリパラメータ付きURLでも正しく判定', () {
        const record = EmojiRecord(
          name: 'test',
          aliases: [],
          url: 'https://example.com/emoji.gif?size=large',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
          denyRoleIds: [],
        );

        expect(record.animated, isTrue); // パス部分で正しく判定
      });
    });

    test('constコンストラクタで不変オブジェクトを作成', () {
      const record1 = EmojiRecord(
        name: 'test',
        aliases: [],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      const record2 = EmojiRecord(
        name: 'test',
        aliases: [],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      // 同じconstインスタンスは同一オブジェクトになる
      expect(identical(record1, record2), isTrue);
    });
  });
}
