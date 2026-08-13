import 'catalog.dart';

/// [EmojiCatalog]のメモリ実装
///
/// - データソースから最新の絵文字一覧を取得
/// - メモリにTTL付きで保持
/// - 同期エラー時にはクールダウンを適用
class InMemoryEmojiCatalog extends EmojiCatalogBase {
  InMemoryEmojiCatalog({
    required super.source,
    super.ttl,
    super.errorCooldown,
    super.onSyncError,
  });
}
