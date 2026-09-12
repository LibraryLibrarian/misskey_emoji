import '../cache/emoji_store.dart';
import '../models/emoji_record.dart';
import 'catalog.dart';

/// [EmojiStore]を用いた永続化対応の[EmojiCatalog]実装
///
/// - 初回アクセス時に[store]からキャッシュをロード
/// - 同期成功後は最新の絵文字を[store]に保存
/// - TTLとエラー時クールダウンを尊重して無駄な再試行を避ける
class PersistentEmojiCatalog extends EmojiCatalogBase {
  PersistentEmojiCatalog({
    required this.store,
    required super.source,
    this.ownsStore = true,
    super.ttl,
    super.errorCooldown,
    super.onSyncError,
  });

  /// 絵文字キャッシュを保持する永続ストア
  final EmojiStore store;

  /// このカタログが[store]の所有権を持つかどうか
  ///
  /// true（既定）の場合、dispose()でstore.dispose()も呼ぶ。複数のカタログで
  /// 1つのストアを共有する場合はfalseを指定し、ストアの破棄は呼び出し側が行う。
  final bool ownsStore;

  bool _restored = false;
  Future<void>? _disposing;

  /// 初回呼び出しでは[store]からのロードを試みる
  @override
  Future<void> beforeSync() async {
    if (_restored) return;

    final snapshot = await store.load();
    if (snapshot.records.isNotEmpty) {
      byKey = indexRecords(snapshot.records);
    }
    final syncedAt = snapshot.syncedAt;
    if (syncedAt != null) {
      restoreLastSyncedAt(syncedAt);
    }
    _restored = true;
  }

  /// ストアの保存契約に従い、name重複を後勝ちで除去する
  ///
  /// ストアから復元した後も同期直後と同じエイリアス解決結果にするため、
  /// インデックス化の前に行う。
  @override
  List<EmojiRecord> normalizeFetchedRecords(List<EmojiRecord> records) {
    final recordsByName = <String, EmojiRecord>{};
    for (final record in records) {
      recordsByName.remove(record.name);
      recordsByName[record.name] = record;
    }
    return recordsByName.values.toList(growable: false);
  }

  /// 同期成功後は最新の絵文字と同期時刻を[store]に保存
  @override
  Future<void> afterFetch(
    List<EmojiRecord> records, {
    required DateTime syncedAt,
  }) async {
    await store.save(records, syncedAt: syncedAt);
  }

  /// 進行中の同期を待機し、同期が失敗した場合も所有ストアを破棄する
  ///
  /// 同期とストアの破棄が両方失敗した場合は、破棄エラーを優先して送出する。
  /// リソース解放の失敗を呼び出し側に伝えるためであり、同期エラーは
  /// dispose()からは送出しないが、元のsync()のFutureから確認できる。
  /// ストアの破棄が成功した場合は、同期エラーをそのまま送出する。
  ///
  /// 複数回呼び出した場合は、ストアの破棄まで含む同じFutureを返す。
  /// 終了処理が失敗した後も再実行せず、同じエラーを返す。
  @override
  Future<void> dispose() => _disposing ??= _dispose();

  Future<void> _dispose() async {
    try {
      await super.dispose();
    } finally {
      if (ownsStore) {
        await store.dispose();
      }
    }
  }
}
