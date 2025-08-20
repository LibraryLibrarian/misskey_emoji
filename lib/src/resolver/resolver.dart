import '../catalog/catalog.dart';
import '../models/emoji_record.dart';

/// 解決済みの絵文字画像情報（描画に必要な最小限の属性）
class EmojiImage {
  /// 画像の URL
  final Uri url;

  /// アニメーションかどうか（拡張子による簡易判定）
  final bool animated;

  /// センシティブフラグ
  final bool isSensitive;

  const EmojiImage({required this.url, required this.animated, required this.isSensitive});
}

/// ショートコードを表示可能な[EmojiImage]に解決する
abstract class EmojiResolver {
  /// 周囲のコロン有無に関わらずショートコードから[EmojiImage]を解決する
  /// 見つからない場合はnullを返す
  Future<EmojiImage?> resolve(String shortcodeOrColonWrapped);
}

/// [EmojiCatalog]を用いたデフォルトのリゾルバ実装
class MisskeyEmojiResolver implements EmojiResolver {
  /// 参照・同期に用いるカタログ
  final EmojiCatalog catalog;

  MisskeyEmojiResolver(this.catalog);

  @override
  /// ショートコードを[EmojiImage]に解決する
  ///
  /// キャッシュミス時には1度だけ同期してから再試行する
  Future<EmojiImage?> resolve(String code) async {
    final rec = catalog.get(code) ?? (await _syncAndRetry(code));
    if (rec == null) return null;
    return EmojiImage(
      url: Uri.parse(rec.url),
      animated: rec.animated,
      isSensitive: rec.isSensitive,
    );
  }

  Future<EmojiRecord?> _syncAndRetry(String code) async {
    await catalog.sync();
    return catalog.get(code);
  }
}


