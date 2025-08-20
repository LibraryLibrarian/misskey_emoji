import '../catalog/catalog.dart';
import '../models/emoji_record.dart';

class EmojiImage {
  final Uri url;
  final bool animated;
  final bool isSensitive;
  const EmojiImage({required this.url, required this.animated, required this.isSensitive});
}

abstract class EmojiResolver {
  Future<EmojiImage?> resolve(String shortcodeOrColonWrapped);
}

class MisskeyEmojiResolver implements EmojiResolver {
  final EmojiCatalog catalog;
  MisskeyEmojiResolver(this.catalog);

  @override
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


