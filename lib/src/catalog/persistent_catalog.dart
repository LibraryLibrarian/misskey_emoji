import '../cache/emoji_store.dart';
import '../models/emoji_record.dart';
import 'catalog.dart';

/// [EmojiStore]を用いた永続化対応の[EmojiCatalog]実装
///
/// - 初回アクセス時に[store]からキャッシュをロード
/// - キャッシュが空ならmetaで事前充填
/// - 同期成功後は最新の絵文字を[store]に保存
/// - TTLとエラー時クールダウンを尊重して無駄な再試行を避ける
class PersistentEmojiCatalog extends EmojiCatalogBase {
  PersistentEmojiCatalog({
    required this.store,
    required super.api,
    super.meta,
    super.ttl,
    super.errorCooldown,
  });

  /// 絵文字キャッシュを保持する永続ストア
  final EmojiStore store;

  /// 初回呼び出しでは[store]からのロードを試みる
  @override
  Future<void> beforeSync() async {
    if (byKey.isEmpty) {
      final cached = await store.loadAll();
      if (cached.isNotEmpty) {
        byKey = indexRecords(cached);
      }
    }
  }

  /// 同期成功後は最新の絵文字を[store]に保存
  @override
  Future<void> afterFetch(List<EmojiRecord> records) async {
    await store.saveAll(records);
  }
}
