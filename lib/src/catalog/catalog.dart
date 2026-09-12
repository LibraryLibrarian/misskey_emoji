import 'package:meta/meta.dart';

import '../models/emoji_record.dart';
import '../source/emoji_source.dart';
import '../util/shortcode.dart';

/// 絵文字の参照・同期を行う読み取り専用カタログのインターフェース
abstract class EmojiCatalog {
  /// サーバーや永続ストアから内部インデックスを同期
  Future<void> sync({bool force = false});

  /// 指定したショートコードに対応する[EmojiRecord]を返す（なければnull）
  EmojiRecord? get(String shortcode);

  /// 正規化済みショートコードからレコードへの不変マップを返す
  Map<String, EmojiRecord> snapshot();

  /// カタログが使用するリソースをクリーンアップする
  ///
  /// カタログが不要になった時に呼び出す
  /// 進行中の同期処理がある場合は、それが完了するまで待機
  Future<void> dispose();
}

/// 同期エラー時のコールバック型定義
typedef SyncErrorCallback =
    void Function(Exception error, StackTrace stackTrace);

/// 共通ロジックを提供するカタログのベースクラス
abstract class EmojiCatalogBase implements EmojiCatalog {
  EmojiCatalogBase({
    required this.source,
    this.ttl = const Duration(minutes: 30),
    this.errorCooldown = const Duration(minutes: 2),
    this.onSyncError,
  });

  /// 絵文字取得に用いるデータソース
  final EmojiSource source;

  /// 同期のTTL。この時間内は再同期をスキップ
  final Duration ttl;

  /// 同期失敗後に適用するクールダウン時間
  final Duration errorCooldown;

  /// 同期エラー時に呼ばれるオプショナルなコールバック
  /// デバッグやエラー監視に利用可能
  final SyncErrorCallback? onSyncError;

  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _lastError;
  Future<void>? _ongoing;
  Future<void>? _disposing;
  bool _disposed = false;

  /// 正規化済みショートコードとレコードのインデックス
  Map<String, EmojiRecord> byKey = {};

  /// 指定ショートコードのレコードを返す（なければnull）
  @override
  EmojiRecord? get(String code) => byKey[normalizeShortcode(code)];

  /// 現在のインデックスの不変スナップショットを返す
  @override
  Map<String, EmojiRecord> snapshot() => Map.unmodifiable(byKey);

  /// カタログをデータソース経由で同期する
  ///
  /// - [force]がfalseの場合、[ttl]と[errorCooldown]を尊重する
  /// - 進行中の同期がある場合、それを待機する（複数の呼び出しが1回の同期を共有）
  @override
  Future<void> sync({bool force = false}) async {
    if (_disposed) {
      throw StateError('Cannot sync a disposed EmojiCatalog');
    }

    // 進行中の同期があれば、それを待って完了
    // 複数のsync呼び出しが同時にあった場合、すべてが同じ1回の同期を共有する
    _ongoing ??= _runSync(force);
    try {
      await _ongoing;
    } finally {
      _ongoing = null;
    }
  }

  Future<void> _runSync(bool force) async {
    await beforeSync();

    final now = DateTime.now();
    if (!force) {
      if (now.difference(_last) < ttl) return;
      if (_lastError != null && now.difference(_lastError!) < errorCooldown) {
        return;
      }
    }
    await _doSync();
  }

  Future<void> _doSync() async {
    try {
      final fetchedRecords = await source.fetchAll();
      final records = normalizeFetchedRecords(fetchedRecords);
      byKey = indexRecords(records);
      final syncedAt = DateTime.now();
      await afterFetch(records, syncedAt: syncedAt);
      _last = syncedAt;
      _lastError = null;
    } on Exception catch (e, stackTrace) {
      // 既存のキャッシュを保持; エラー時間を記録してクールダウンを適用
      _lastError = DateTime.now();
      // エラーコールバックがあれば通知
      onSyncError?.call(e, stackTrace);
    }
  }

  /// 取得したレコード一覧をカタログ用に正規化する
  ///
  /// 既定では取得順序を含めて入力をそのまま返す。永続カタログだけは、保存後の復元時も
  /// 同じ解決結果にするため、ストアの保存契約に合わせてname重複を除去する。
  @protected
  List<EmojiRecord> normalizeFetchedRecords(List<EmojiRecord> records) =>
      records;

  /// レコード一覧を正規化済みショートコードのマップに変換する
  Map<String, EmojiRecord> indexRecords(List<EmojiRecord> list) {
    final map = <String, EmojiRecord>{};
    for (final e in list) {
      map[e.name] = e;
      for (final a in e.aliases) {
        map[a] = e;
      }
    }
    return map;
  }

  /// サブクラスが永続化された同期時刻を復元するために用いる
  @protected
  // ignore: use_setters_to_change_properties
  void restoreLastSyncedAt(DateTime value) => _last = value;

  /// サブクラスで同期前の処理を実装（例：ストアからのロード）
  @protected
  Future<void> beforeSync() async {}

  /// サブクラスでフェッチ後の処理を実装（例：ストアへの保存）
  ///
  /// [syncedAt]は同期成功時刻である。
  @protected
  Future<void> afterFetch(
    List<EmojiRecord> records, {
    required DateTime syncedAt,
  }) async {}

  /// 新規同期を拒否し、進行中の同期の完了を待つ
  ///
  /// 複数回呼び出した場合は同じFutureを返し、同期の成功・失敗を共有する。
  @override
  Future<void> dispose() => _disposing ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    await _ongoing;
  }
}
