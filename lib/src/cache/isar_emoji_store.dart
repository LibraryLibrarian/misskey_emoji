import 'package:isar_community/isar.dart';

import '../models/emoji_record.dart';
import 'emoji_store.dart';

part 'isar_emoji_store.g.dart';

/// キャッシュされた絵文字レコードを表すIsarエンティティ
@Collection()
class EmojiRecordEntity {
  Id id = Isar.autoIncrement;

  late String name;
  late List<String> aliases;
  String? category;
  late String url;
  late bool localOnly;
  late bool isSensitive;
  late List<String> allowRoleIds;
  late List<String> denyRoleIds;
}

/// [EmojiRecord]を[EmojiRecordEntity]に変換する処理
EmojiRecordEntity toEntity(EmojiRecord r) {
  final e = EmojiRecordEntity()
    ..name = r.name
    ..aliases = List<String>.from(r.aliases)
    ..category = r.category
    ..url = r.url
    ..localOnly = r.localOnly
    ..isSensitive = r.isSensitive
    ..allowRoleIds = List<String>.from(r.allowRoleIds)
    ..denyRoleIds = List<String>.from(r.denyRoleIds);
  return e;
}

/// [EmojiRecordEntity]を[EmojiRecord]に変換する処理
EmojiRecord fromEntity(EmojiRecordEntity e) {
  return EmojiRecord(
    name: e.name,
    aliases: List<String>.from(e.aliases),
    url: e.url,
    category: e.category,
    localOnly: e.localOnly,
    isSensitive: e.isSensitive,
    allowRoleIds: List<String>.from(e.allowRoleIds),
    denyRoleIds: List<String>.from(e.denyRoleIds),
  );
}

/// [EmojiStore]のIsar実装
class IsarEmojiStore implements EmojiStore {
  /// オープン済みのIsarインスタンス
  final Isar isar;
  IsarEmojiStore(this.isar);

  @override
  Future<List<EmojiRecord>> loadAll() async {
    final list = await isar.emojiRecordEntitys.where().findAll();
    return list.map(fromEntity).toList(growable: false);
  }

  @override
  Future<void> saveAll(List<EmojiRecord> all) async {
    await isar.writeTxn(() async {
      await isar.emojiRecordEntitys.clear();
      await isar.emojiRecordEntitys.putAll(all.map(toEntity).toList());
    });
  }
}
