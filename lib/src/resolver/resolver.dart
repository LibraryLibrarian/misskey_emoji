import '../catalog/catalog.dart';
import '../models/emoji_record.dart';

/// 解決済みの絵文字画像情報（描画に必要な最小限の属性）
class EmojiImage {
  const EmojiImage({
    required this.url,
    required this.animated,
    required this.isSensitive,
  });

  /// 画像の URL
  final Uri url;

  /// アニメーションかどうか（拡張子による簡易判定）
  final bool animated;

  /// センシティブフラグ
  final bool isSensitive;
}

/// ショートコードを表示可能な[EmojiImage]に解決する関数型
///
/// 周囲のコロン有無に関わらずショートコードから[EmojiImage]を解決する
/// 見つからない場合はnullを返す
typedef EmojiResolver =
    Future<EmojiImage?> Function(
      String shortcodeOrColonWrapped,
    );

/// [EmojiCatalog]を用いたデフォルトのリゾルバ実装
class MisskeyEmojiResolver {
  MisskeyEmojiResolver(this.catalog);

  /// 参照・同期に用いるカタログ
  final EmojiCatalog catalog;

  bool _disposed = false;

  /// ショートコードを[EmojiImage]に解決する
  ///
  /// キャッシュミス時には1度だけ同期してから再試行する
  Future<EmojiImage?> resolve(String code) async {
    if (_disposed) {
      throw StateError('Cannot resolve using a disposed MisskeyEmojiResolver');
    }
    final rec = catalog.get(code) ?? (await _syncAndRetry(code));
    if (rec == null) return null;
    return EmojiImage(
      url: Uri.parse(rec.url),
      animated: rec.animated,
      isSensitive: rec.isSensitive,
    );
  }

  /// 関数オブジェクトとして呼び出せるようにする
  Future<EmojiImage?> call(String code) => resolve(code);

  /// リゾルバーが使用するリソースをクリーンアップする
  ///
  /// 注意: このメソッドはカタログ自体のdisposeは呼び出さない
  /// カタログのライフサイクルは呼び出し側が管理する必要がある
  Future<void> dispose() async {
    _disposed = true;
  }

  Future<EmojiRecord?> _syncAndRetry(String code) async {
    await catalog.sync();
    return catalog.get(code);
  }
}
