import 'package:misskey_api_core/misskey_api_core.dart';

import '../models/emoji_dto.dart';
import '../models/emoji_record.dart';
import '../util/shortcode.dart';

/// Misskeyの絵文字APIラッパー
class MisskeyEmojiApi {
  /// misskey_api_coreの低レベルHTTPクライアント
  final MisskeyHttpClient http;
  MisskeyEmojiApi(this.http);

  /// Misskeyサーバーからカスタム絵文字の一覧を取得する処理
  ///
  /// HTTPメソッドは明示的にGETを使用する。レスポンスは[toRecord]を通して[EmojiRecord]に変換される。
  Future<List<EmojiRecord>> fetchAll() async {
    final res = await http.send<Map<String, dynamic>>(
      '/emojis',
      method: 'GET',
      options: const RequestOptions(authRequired: false, idempotent: true),
    );
    final list = (res['emojis'] as List).cast<Map<String, dynamic>>();
    return list.map((j) => toRecord(EmojiDto.fromJson(j))).toList(growable: false);
  }

  /// [EmojiDto]を正規化した[EmojiRecord]に変換する処理
  EmojiRecord toRecord(EmojiDto d) {
    final name = normalizeShortcode(d.name);
    final aliases = d.aliases.map(normalizeShortcode).toSet().toList();
    return EmojiRecord(
      name: name,
      aliases: aliases,
      url: d.url,
      category: d.category,
      localOnly: d.localOnly ?? false,
      isSensitive: d.isSensitive ?? false,
      allowRoleIds: d.allowRoleIds ?? const [],
      denyRoleIds: d.denyRoleIds ?? const [],
    );
  }
}


