import 'package:misskey_api_core/misskey_api_core.dart';

import '../models/emoji_dto.dart';
import '../models/emoji_record.dart';

class MisskeyEmojiApi {
  final MisskeyHttpClient http;
  MisskeyEmojiApi(this.http);

  Future<List<EmojiRecord>> fetchAll() async {
    Map<String, dynamic> res;
    try {
      res = await http.send<Map<String, dynamic>>(
        '/emojis',
        options: const RequestOptions(authRequired: false, idempotent: true),
      );
    } catch (_) {
      res = await http.send<Map<String, dynamic>>(
        '/emojis',
        method: 'GET',
        options: const RequestOptions(authRequired: false, idempotent: true),
      );
    }
    final list = (res['emojis'] as List).cast<Map<String, dynamic>>();
    return list.map((j) => toRecord(EmojiDto.fromJson(j))).toList(growable: false);
  }

  EmojiRecord toRecord(EmojiDto d) {
    String norm(String s) {
      final t = s.trim();
      final core = (t.startsWith(':') && t.endsWith(':') && t.length >= 2)
          ? t.substring(1, t.length - 1)
          : t;
      return core.toLowerCase();
    }

    final name = norm(d.name);
    final aliases = d.aliases.map(norm).toSet().toList();
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


