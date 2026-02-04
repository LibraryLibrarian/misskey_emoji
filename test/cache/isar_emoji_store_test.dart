import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:misskey_emoji/src/cache/isar_emoji_store.dart';
import 'package:misskey_emoji/src/models/emoji_record.dart';

void main() {
  group('EmojiRecordEntity変換', () {
    test('EmojiRecordからEmojiRecordEntityへの変換', () {
      const record = EmojiRecord(
        name: 'test',
        aliases: ['alias1', 'alias2'],
        url: 'https://example.com/emoji.png',
        category: 'test_category',
        localOnly: true,
        isSensitive: false,
        allowRoleIds: ['role1', 'role2'],
        denyRoleIds: ['role3'],
      );

      final entity = toEntity(record);

      expect(entity.name, equals('test'));
      expect(entity.aliases, equals(['alias1', 'alias2']));
      expect(entity.url, equals('https://example.com/emoji.png'));
      expect(entity.category, equals('test_category'));
      expect(entity.localOnly, isTrue);
      expect(entity.isSensitive, isFalse);
      expect(entity.allowRoleIds, equals(['role1', 'role2']));
      expect(entity.denyRoleIds, equals(['role3']));
    });

    test('EmojiRecordEntityからEmojiRecordへの変換', () {
      final entity = EmojiRecordEntity()
        ..name = 'test'
        ..aliases = ['alias1', 'alias2']
        ..url = 'https://example.com/emoji.png'
        ..category = 'test_category'
        ..localOnly = true
        ..isSensitive = false
        ..allowRoleIds = ['role1', 'role2']
        ..denyRoleIds = ['role3'];

      final record = fromEntity(entity);

      expect(record.name, equals('test'));
      expect(record.aliases, equals(['alias1', 'alias2']));
      expect(record.url, equals('https://example.com/emoji.png'));
      expect(record.category, equals('test_category'));
      expect(record.localOnly, isTrue);
      expect(record.isSensitive, isFalse);
      expect(record.allowRoleIds, equals(['role1', 'role2']));
      expect(record.denyRoleIds, equals(['role3']));
    });

    test('カテゴリなしのレコード変換', () {
      const record = EmojiRecord(
        name: 'test',
        aliases: [],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      final entity = toEntity(record);
      final converted = fromEntity(entity);

      expect(converted.category, isNull);
    });

    test('往復変換で情報が保持される', () {
      const original = EmojiRecord(
        name: 'test_emoji',
        aliases: ['alias'],
        url: 'https://example.com/emoji.gif',
        category: 'category',
        localOnly: true,
        isSensitive: true,
        allowRoleIds: ['role1'],
        denyRoleIds: ['role2'],
      );

      final entity = toEntity(original);
      final converted = fromEntity(entity);

      expect(converted.name, equals(original.name));
      expect(converted.aliases, equals(original.aliases));
      expect(converted.url, equals(original.url));
      expect(converted.category, equals(original.category));
      expect(converted.localOnly, equals(original.localOnly));
      expect(converted.isSensitive, equals(original.isSensitive));
      expect(converted.allowRoleIds, equals(original.allowRoleIds));
      expect(converted.denyRoleIds, equals(original.denyRoleIds));
    });

    test('リストが独立してコピーされる', () {
      final originalAliases = ['alias1', 'alias2'];
      final record = EmojiRecord(
        name: 'test',
        aliases: originalAliases,
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      final entity = toEntity(record);
      final convertedRecord = fromEntity(entity);

      // リストが独立している
      expect(identical(originalAliases, convertedRecord.aliases), isFalse);
      expect(convertedRecord.aliases, equals(originalAliases));
    });
  });

  // 注意: Isarのテストはネイティブライブラリが必要なため、
  // ユニットテストではスキップされます。実機/エミュレータでのテストが必要です。
  group('IsarEmojiStore', skip: 'Isarのネイティブライブラリが必要', () {
    late Isar isar;
    late IsarEmojiStore store;

    setUp(() async {
      // テスト用にメモリ上のIsarを使用
      isar = await Isar.open(
        [EmojiRecordEntitySchema],
        name: 'test_emoji_${DateTime.now().millisecondsSinceEpoch}',
        directory: '',
      );
      store = IsarEmojiStore(isar);
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
    });

    test('初期状態では空のリストを返す', () async {
      final records = await store.loadAll();
      expect(records, isEmpty);
    });

    test('絵文字を保存できる', () async {
      const record = EmojiRecord(
        name: 'test_emoji',
        aliases: ['alias1'],
        url: 'https://example.com/emoji.png',
        category: 'test',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      await store.saveAll([record]);

      final loaded = await store.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.name, equals('test_emoji'));
    });

    test('複数の絵文字を保存できる', () async {
      const records = [
        EmojiRecord(
          name: 'emoji1',
          aliases: [],
          url: 'https://example.com/emoji1.png',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
          denyRoleIds: [],
        ),
        EmojiRecord(
          name: 'emoji2',
          aliases: [],
          url: 'https://example.com/emoji2.png',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
          denyRoleIds: [],
        ),
      ];

      await store.saveAll(records);

      final loaded = await store.loadAll();
      expect(loaded, hasLength(2));
      expect(loaded.map((r) => r.name), containsAll(['emoji1', 'emoji2']));
    });

    test('saveAllで既存のデータが置き換えられる', () async {
      const records1 = [
        EmojiRecord(
          name: 'emoji1',
          aliases: [],
          url: 'https://example.com/emoji1.png',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
          denyRoleIds: [],
        ),
      ];

      const records2 = [
        EmojiRecord(
          name: 'emoji2',
          aliases: [],
          url: 'https://example.com/emoji2.png',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
          denyRoleIds: [],
        ),
      ];

      await store.saveAll(records1);
      await store.saveAll(records2);

      final loaded = await store.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.name, equals('emoji2'));
    });

    test('空のリストを保存するとすべてクリアされる', () async {
      const record = EmojiRecord(
        name: 'emoji',
        aliases: [],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      await store.saveAll([record]);
      await store.saveAll([]);

      final loaded = await store.loadAll();
      expect(loaded, isEmpty);
    });

    test('大量のデータを保存・読み込みできる', () async {
      final records = List.generate(
        1000,
        (i) => EmojiRecord(
          name: 'emoji_$i',
          aliases: ['alias_$i'],
          url: 'https://example.com/emoji_$i.png',
          category: 'category_${i % 10}',
          localOnly: i.isEven,
          isSensitive: i % 3 == 0,
          allowRoleIds: ['role_$i'],
          denyRoleIds: [],
        ),
      );

      await store.saveAll(records);

      final loaded = await store.loadAll();
      expect(loaded, hasLength(1000));
    });

    test('特殊文字を含む絵文字を保存できる', () async {
      const record = EmojiRecord(
        name: 'emoji_特殊文字_🎉',
        aliases: ['alias_テスト'],
        url: 'https://example.com/emoji-test.png?size=large&format=png',
        category: 'カテゴリ',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      await store.saveAll([record]);

      final loaded = await store.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.name, equals('emoji_特殊文字_🎉'));
      expect(loaded.first.aliases, equals(['alias_テスト']));
      expect(loaded.first.category, equals('カテゴリ'));
    });

    test('すべてのフィールドが正しく保存・読み込みされる', () async {
      const record = EmojiRecord(
        name: 'complex_emoji',
        aliases: ['alias1', 'alias2', 'alias3'],
        url: 'https://example.com/complex.gif',
        category: 'complex_category',
        localOnly: true,
        isSensitive: true,
        allowRoleIds: ['role1', 'role2', 'role3'],
        denyRoleIds: ['role4', 'role5'],
      );

      await store.saveAll([record]);

      final loaded = await store.loadAll();
      expect(loaded, hasLength(1));

      final loadedRecord = loaded.first;
      expect(loadedRecord.name, equals(record.name));
      expect(loadedRecord.aliases, equals(record.aliases));
      expect(loadedRecord.url, equals(record.url));
      expect(loadedRecord.category, equals(record.category));
      expect(loadedRecord.localOnly, equals(record.localOnly));
      expect(loadedRecord.isSensitive, equals(record.isSensitive));
      expect(loadedRecord.allowRoleIds, equals(record.allowRoleIds));
      expect(loadedRecord.denyRoleIds, equals(record.denyRoleIds));
    });

    test('growableがfalseで読み込まれる', () async {
      const record = EmojiRecord(
        name: 'test',
        aliases: [],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
        denyRoleIds: [],
      );

      await store.saveAll([record]);

      final loaded = await store.loadAll();
      expect(loaded, hasLength(1));
      // growable: false のリストなので追加できない
      expect(() => loaded.add(record), throwsUnsupportedError);
    });
  });
}
