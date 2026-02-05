import 'catalog.dart';

/// [EmojiCatalog]のメモリ実装
///
/// - キャッシュが空の場合、`meta`から事前充填
/// - APIから最新の絵文字一覧を取得
/// - メモリにTTL付きで保持
/// - 同期エラー時にはクールダウンを適用
class InMemoryEmojiCatalog extends EmojiCatalogBase {
  InMemoryEmojiCatalog({
    required super.api,
    super.meta,
    super.ttl,
    super.errorCooldown,
  });
}
