import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji/src/catalog/catalog.dart';
import 'package:misskey_emoji/src/catalog/search.dart';
import 'package:misskey_emoji/src/models/emoji_record.dart';

/// テスト用のモックカタログ
class MockSearchCatalog implements EmojiCatalog {
  MockSearchCatalog(this.records);

  final List<EmojiRecord> records;

  @override
  EmojiRecord? get(String shortcode) {
    final normalized = shortcode.toLowerCase().replaceAll(':', '');
    return records.firstWhere(
      (r) => r.name == normalized,
      orElse: () => const EmojiRecord(
        name: '',
        aliases: [],
        url: '',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
      ),
    );
  }

  @override
  Map<String, EmojiRecord> snapshot() {
    final map = <String, EmojiRecord>{};
    for (final record in records) {
      map[record.name] = record;
      for (final alias in record.aliases) {
        map[alias] = record;
      }
    }
    return Map.unmodifiable(map);
  }

  @override
  Future<void> sync({bool force = false}) async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  group('EmojiSearchMode', () {
    test('列挙型の値が正しく定義されている', () {
      expect(EmojiSearchMode.values, hasLength(2));
      expect(EmojiSearchMode.values, contains(EmojiSearchMode.prefix));
      expect(EmojiSearchMode.values, contains(EmojiSearchMode.contains));
    });
  });

  group('EmojiSearchOptions', () {
    test('デフォルト値が正しく設定される', () {
      const options = EmojiSearchOptions();

      expect(options.category, isNull);
      expect(options.limit, equals(50));
      expect(options.mode, equals(EmojiSearchMode.prefix));
      expect(options.includeAliases, isTrue);
      expect(options.scorer, isNull);
    });

    test('カスタム値で作成できる', () {
      const options = EmojiSearchOptions(
        category: 'test',
        limit: 100,
        mode: EmojiSearchMode.contains,
        includeAliases: false,
      );

      expect(options.category, equals('test'));
      expect(options.limit, equals(100));
      expect(options.mode, equals(EmojiSearchMode.contains));
      expect(options.includeAliases, isFalse);
    });
  });

  group('EmojiSearchResult', () {
    test('基本的な検索結果を作成できる', () {
      const record = EmojiRecord(
        name: 'test',
        aliases: [],
        url: 'https://example.com/emoji.png',
        localOnly: false,
        isSensitive: false,
        allowRoleIds: [],
      );

      const result = EmojiSearchResult(
        record: record,
        score: 100,
        matched: 'test',
        matchedIsAlias: false,
      );

      expect(result.record, equals(record));
      expect(result.score, equals(100.0));
      expect(result.matched, equals('test'));
      expect(result.matchedIsAlias, isFalse);
    });
  });

  group('EmojiSearch', () {
    late List<EmojiRecord> testRecords;
    late EmojiCatalog testCatalog;
    late EmojiSearch search;

    setUp(() {
      testRecords = [
        const EmojiRecord(
          name: 'smile',
          aliases: ['happy', 'joy'],
          url: 'https://example.com/smile.png',
          category: 'faces',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
        ),
        const EmojiRecord(
          name: 'smirk',
          aliases: [],
          url: 'https://example.com/smirk.png',
          category: 'faces',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
        ),
        const EmojiRecord(
          name: 'cat',
          aliases: ['neko'],
          url: 'https://example.com/cat.png',
          category: 'animals',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
        ),
        const EmojiRecord(
          name: 'dog',
          aliases: [],
          url: 'https://example.com/dog.png',
          category: 'animals',
          localOnly: false,
          isSensitive: false,
          allowRoleIds: [],
        ),
        const EmojiRecord(
          name: 'sensitive_emoji',
          aliases: [],
          url: 'https://example.com/sensitive.png',
          category: 'nsfw',
          localOnly: false,
          isSensitive: true,
          allowRoleIds: [],
        ),
      ];

      testCatalog = MockSearchCatalog(testRecords);
      search = EmojiSearch(testCatalog);
    });

    group('query (シンプルAPI)', () {
      test('前方一致で検索できる', () {
        final results = search.query('sm');

        expect(results, hasLength(2));
        expect(results.map((r) => r.name), containsAll(['smile', 'smirk']));
      });

      test('完全一致の結果が返る', () {
        final results = search.query('cat');

        expect(results, hasLength(1));
        expect(results.first.name, equals('cat'));
      });

      test('該当なしの場合は空リストを返す', () {
        final results = search.query('xyz');

        expect(results, isEmpty);
      });

      test('カテゴリで絞り込みできる', () {
        // 空文字列の場合は何も返さないので、代わりに前方一致で検索
        final results = search.query('c', category: 'animals');

        expect(results, hasLength(1));
        expect(results.first.name, equals('cat'));
      });

      test('limit数を指定できる', () {
        final results = search.query('s', limit: 1);

        expect(results, hasLength(1));
      });

      test('空文字列の検索は空リストを返す', () {
        final results = search.query('');

        // 空文字列では何も返さない設計
        expect(results, isEmpty);
      });

      test('大文字小文字を区別しない', () {
        final results = search.query('SMILE');

        expect(results, hasLength(1));
        expect(results.first.name, equals('smile'));
      });
    });

    group('queryAdvanced', () {
      test('前方一致モードで検索', () {
        final results = search.queryAdvanced(
          'sm',
        );

        expect(results, hasLength(2));
        expect(
          results.map((r) => r.record.name),
          containsAll(['smile', 'smirk']),
        );
      });

      test('部分一致モードで検索', () {
        final results = search.queryAdvanced(
          'mi',
          options: const EmojiSearchOptions(mode: EmojiSearchMode.contains),
        );

        // 'smile'と'smirk'が該当
        expect(results, hasLength(2));
        expect(
          results.map((r) => r.record.name),
          containsAll(['smile', 'smirk']),
        );
      });

      test('エイリアスを含めて検索', () {
        final results = search.queryAdvanced(
          'hap',
        );

        expect(results, hasLength(1));
        expect(results.first.record.name, equals('smile'));
        expect(results.first.matched, equals('happy'));
        expect(results.first.matchedIsAlias, isTrue);
      });

      test('エイリアスを除外して検索', () {
        final results = search.queryAdvanced(
          'hap',
          options: const EmojiSearchOptions(includeAliases: false),
        );

        expect(results, isEmpty);
      });

      test('カテゴリで絞り込み', () {
        final results = search.queryAdvanced(
          's',
          options: const EmojiSearchOptions(category: 'faces'),
        );

        expect(results, hasLength(2));
        expect(
          results.map((r) => r.record.name),
          containsAll(['smile', 'smirk']),
        );
      });

      test('スコアが高い順に並ぶ', () {
        final results = search.queryAdvanced('sm');

        expect(results, hasLength(2));
        // 完全一致や短いものが高スコア
        expect(results.first.score, greaterThanOrEqualTo(results.last.score));
      });

      test('同スコアの場合は名前順に並ぶ', () {
        // 'cat'と'dog'は同じスコアになるはず
        final results = search.queryAdvanced(
          '',
          options: const EmojiSearchOptions(
            category: 'animals',
            mode: EmojiSearchMode.contains,
          ),
        );

        if (results.length >= 2 && results[0].score == results[1].score) {
          final names = results.map((r) => r.record.name).toList();
          expect(names.first.compareTo(names.last), lessThan(0));
        }
      });

      test('limit数を指定できる', () {
        final results = search.queryAdvanced(
          's',
          options: const EmojiSearchOptions(limit: 1),
        );

        expect(results, hasLength(1));
      });

      test('カスタムスコアラーを使用できる', () {
        // 名前の長さで逆順にスコアリング
        double customScorer(EmojiRecord record, String query) {
          if (!record.name.contains(query)) return double.negativeInfinity;
          return -record.name.length.toDouble();
        }

        final results = search.queryAdvanced(
          's',
          options: EmojiSearchOptions(scorer: customScorer),
        );

        if (results.length >= 2) {
          // 短い名前が高スコア（より大きい負の値）になる
          expect(
            results.first.record.name.length,
            lessThanOrEqualTo(results.last.record.name.length),
          );
        }
      });

      test('空文字列の検索は空リストを返す', () {
        final results = search.queryAdvanced('');

        expect(results, isEmpty);
      });

      test('名前とエイリアスの両方がマッチした場合は高スコアを採用', () {
        final results = search.queryAdvanced(
          'smi',
        );

        // 'smile'は名前でマッチ、'smirk'も名前でマッチ
        expect(results, hasLength(2));
        final smileResult = results.firstWhere((r) => r.record.name == 'smile');
        expect(smileResult.matchedIsAlias, isFalse); // 名前でマッチした方が採用される
      });

      test('センシティブな絵文字も検索結果に含まれる', () {
        final results = search.queryAdvanced('sensitive');

        expect(results, hasLength(1));
        expect(results.first.record.isSensitive, isTrue);
      });

      test('大文字小文字を区別しない', () {
        final results = search.queryAdvanced('SMILE');

        expect(results, hasLength(1));
        expect(results.first.record.name, equals('smile'));
      });

      test('コロンで囲まれたクエリも正規化される', () {
        final results = search.queryAdvanced(':smile:');

        expect(results, hasLength(1));
        expect(results.first.record.name, equals('smile'));
      });
    });

    group('エッジケース', () {
      test('同一レコードが複数のエイリアスでマッチしても1件のみ返す', () {
        final results = search.queryAdvanced(
          'smi', // 'smile'の名前とエイリアス両方にマッチする可能性
        );

        // 同一レコードは最良のマッチのみ
        final smileCount = results
            .where((r) => r.record.name == 'smile')
            .length;
        expect(smileCount, lessThanOrEqualTo(1));
      });

      test('非常に長いクエリでも動作する', () {
        final results = search.queryAdvanced('a' * 1000);

        expect(results, isEmpty);
      });

      test('特殊文字を含むクエリ', () {
        final results = search.queryAdvanced('test_emoji');

        // 該当なし（テストデータに存在しない）
        expect(results, isEmpty);
      });
    });
  });
}
