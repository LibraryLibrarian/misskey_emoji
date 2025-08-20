import '../models/emoji_record.dart';
import '../util/shortcode.dart';
import 'catalog.dart';

/// 検索モード
enum EmojiSearchMode {
  /// 前方一致
  prefix,

  /// 部分一致
  contains,
}

/// スコアリング関数の型定義
typedef EmojiScorer = double Function(
    EmojiRecord record, String normalizedQuery);

/// 検索オプション
class EmojiSearchOptions {
  /// カテゴリでの絞り込み（null なら全カテゴリ）
  final String? category;

  /// 最大件数
  final int limit;

  /// 検索モード（前方一致/部分一致）
  final EmojiSearchMode mode;

  /// エイリアスも検索対象に含めるか
  final bool includeAliases;

  /// カスタムスコアラー（未指定時はデフォルトロジック）
  final EmojiScorer? scorer;

  const EmojiSearchOptions({
    this.category,
    this.limit = 50,
    this.mode = EmojiSearchMode.prefix,
    this.includeAliases = true,
    this.scorer,
  });
}

/// 単一の検索結果（スコアとマッチ情報付き）
class EmojiSearchResult {
  /// 対象のレコード
  final EmojiRecord record;

  /// 大きいほど優先度が高い
  final double score;

  /// マッチしたキー（nameまたはalias）
  final String matched;

  /// マッチしたのがaliasかどうか
  final bool matchedIsAlias;

  const EmojiSearchResult({
    required this.record,
    required this.score,
    required this.matched,
    required this.matchedIsAlias,
  });
}

/// [EmojiCatalog]に対する簡易検索ヘルパー
class EmojiSearch {
  /// 検索対象のカタログ
  final EmojiCatalog catalog;
  EmojiSearch(this.catalog);

  /// 互換の簡易API（前方一致）
  ///
  /// 内部的には[queryAdvanced]を呼び出す
  List<EmojiRecord> query(String text, {String? category, int limit = 50}) {
    final results = queryAdvanced(text,
        options: EmojiSearchOptions(
          category: category,
          limit: limit,
          mode: EmojiSearchMode.prefix,
        ));
    return results.map((r) => r.record).toList(growable: false);
  }

  /// 拡張検索API
  ///
  /// - 正規化済みテキストで前方一致/部分一致
  /// - カテゴリ絞込
  /// - スコアリングで並び替え（デフォルト実装あり）
  /// - 同一レコードは最良の一致のみを採用
  List<EmojiSearchResult> queryAdvanced(String text,
      {EmojiSearchOptions options = const EmojiSearchOptions()}) {
    final q = normalizeShortcode(text);
    if (q.isEmpty) return const <EmojiSearchResult>[];

    final all = catalog.snapshot().values;

    final scorer = options.scorer ?? _defaultScorer(options.mode);

    final byRecord = <EmojiRecord, EmojiSearchResult>{};
    for (final e in all) {
      // カテゴリフィルタ
      if (options.category != null && e.category != options.category) {
        continue;
      }

      // nameの評価
      final nameScore = _scoreIfMatch(e.name, q, scorer);
      EmojiSearchResult? best;
      if (nameScore != null) {
        best = EmojiSearchResult(
            record: e,
            score: nameScore,
            matched: e.name,
            matchedIsAlias: false);
      }

      // aliasの評価
      if (options.includeAliases) {
        for (final a in e.aliases) {
          final s = _scoreIfMatch(a, q, scorer);
          if (s != null) {
            final candidate = EmojiSearchResult(
                record: e, score: s, matched: a, matchedIsAlias: true);
            if (best == null || candidate.score > best.score) {
              best = candidate;
            }
          }
        }
      }

      if (best != null) {
        final prev = byRecord[e];
        if (prev == null || best.score > prev.score) {
          byRecord[e] = best;
        }
      }
    }

    final list = byRecord.values.toList();
    // スコア降順、同点は名前昇順
    list.sort((a, b) {
      final c = b.score.compareTo(a.score);
      if (c != 0) return c;
      return a.record.name.compareTo(b.record.name);
    });
    if (list.length > options.limit) {
      return list.sublist(0, options.limit);
    }
    return list;
  }

  double? _scoreIfMatch(String key, String q, EmojiScorer scorer) {
    // ダミー生成を避け、文字列キーに対する評価のみを行う
    return _matchScore(key, q, scorer);
  }

  // キーとクエリに対しscorerを用いたスコアを計算する
  double? _matchScore(String key, String q, EmojiScorer scorer) {
    final s = _scorerWrap(scorer, key, q);
    return s > double.negativeInfinity ? s : null;
  }

  // デフォルトスコアラー（前方一致/部分一致）
  EmojiScorer _defaultScorer(EmojiSearchMode mode) {
    return (EmojiRecord e, String q) {
      final key = e.name; // e.nameにはnormalizeShortcode済みの前提
      if (key == q) return 100.0;
      final idx = key.indexOf(q);
      if (idx < 0) return double.negativeInfinity;
      if (mode == EmojiSearchMode.prefix && idx != 0) {
        return double.negativeInfinity;
      }
      // 位置が早いほど高スコア、短い方が高スコア
      final lengthPenalty = key.length * 0.01;
      final posPenalty = idx * 0.1;
      final base = (mode == EmojiSearchMode.prefix) ? 90.0 : 70.0;
      return base - lengthPenalty - posPenalty;
    };
  }

  // scorerをキー単位で使えるようラップ（EmojiRecordのnameをキーとして扱う）
  double _scorerWrap(EmojiScorer scorer, String key, String q) {
    final dummy = EmojiRecord(
      name: key,
      aliases: const [],
      url: '',
      category: null,
      localOnly: false,
      isSensitive: false,
      allowRoleIds: const [],
      denyRoleIds: const [],
    );
    return scorer(dummy, q);
  }
}
