import 'package:misskey_client/misskey_client.dart';

import '../models/emoji_record.dart';
import '../util/shortcode.dart';

/// 絵文字レコードの取得元を表すインターフェース
// ignore: one_member_abstracts
abstract class EmojiSource {
  /// 利用可能なすべての絵文字レコードを取得する
  Future<List<EmojiRecord>> fetchAll();
}

/// [MisskeyClient]を使用する[EmojiSource]実装
class MisskeyClientEmojiSource implements EmojiSource {
  MisskeyClientEmojiSource(this._client);

  final MisskeyClient _client;

  @override
  Future<List<EmojiRecord>> fetchAll() async =>
      (await _client.meta.getEmojis()).map(_toRecord).toList(growable: false);

  EmojiRecord _toRecord(MisskeyCustomEmoji emoji) {
    final aliases = emoji.aliases ?? const [];
    return EmojiRecord(
      name: normalizeShortcode(emoji.shortcode),
      aliases: aliases.map(normalizeShortcode).toSet().toList(growable: false),
      url: emoji.url,
      category: emoji.category,
      localOnly: emoji.localOnly ?? false,
      isSensitive: emoji.isSensitive ?? false,
      allowRoleIds: emoji.roleIdsThatCanBeUsedThisEmojiAsReaction ?? const [],
    );
  }
}
