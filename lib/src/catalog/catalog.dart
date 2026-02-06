import 'package:misskey_api_core/misskey_api_core.dart';

import '../api/misskey_emoji_api.dart';
import '../models/emoji_dto.dart';
import '../models/emoji_record.dart';
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
    required this.api,
    this.meta,
    this.ttl = const Duration(minutes: 30),
    this.errorCooldown = const Duration(minutes: 2),
    this.onSyncError,
  });

  /// 絵文字取得に用いるAPIクライアント
  final MisskeyEmojiApi api;

  /// インスタンスのメタから事前充填するためのMetaClient（任意）
  final MetaClient? meta;

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
  bool _disposed = false;

  /// 正規化済みショートコードとレコードのインデックス
  Map<String, EmojiRecord> byKey = {};

  /// 指定ショートコードのレコードを返す（なければnull）
  @override
  EmojiRecord? get(String code) => byKey[normalizeShortcode(code)];

  /// 現在のインデックスの不変スナップショットを返す
  @override
  Map<String, EmojiRecord> snapshot() => Map.unmodifiable(byKey);

  /// カタログをAPI経由で同期する
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
      if (byKey.isEmpty && meta != null) {
        final m = await meta!.getMeta();
        final metaEmojis =
            (m.raw['emojis'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];
        if (metaEmojis.isNotEmpty) {
          final list = metaEmojis
              .map((j) => api.toRecord(EmojiDto.fromJson(j)))
              .toList();
          byKey = indexRecords(list);
        }
      }
      final newest = await api.fetchAll();
      byKey = indexRecords(newest);
      await afterFetch(newest);
      _last = DateTime.now();
      _lastError = null;
    } on Exception catch (e, stackTrace) {
      // 既存のキャッシュを保持; エラー時間を記録してクールダウンを適用
      _lastError = DateTime.now();
      // エラーコールバックがあれば通知
      onSyncError?.call(e, stackTrace);
    }
  }

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

  /// サブクラスで同期前の処理を実装（例：ストアからのロード）
  Future<void> beforeSync() async {}

  /// サブクラスでフェッチ後の処理を実装（例：ストアへの保存）
  Future<void> afterFetch(List<EmojiRecord> records) async {}

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _ongoing;
  }
}
