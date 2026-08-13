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
    ..allowRoleIds = List<String>.from(r.allowRoleIds);
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
  );
}

/// [EmojiStore]のIsar実装
class IsarEmojiStore implements EmojiStore {
  IsarEmojiStore(this.isar, {this.ownsIsar = false});

  /// オープン済みのIsarインスタンス
  final Isar isar;

  /// このストアがIsarインスタンスの所有権を持つかどうか
  ///
  /// trueの場合、disposeメソッドでIsarインスタンスもクローズする
  /// falseの場合（デフォルト）、Isarインスタンスのクローズは呼び出し側の責任
  final bool ownsIsar;

  bool _disposed = false;

  @override
  Future<List<EmojiRecord>> loadAll() async {
    _checkNotDisposed();
    final list = await isar.emojiRecordEntitys.where().findAll();
    return list.map(fromEntity).toList(growable: false);
  }

  @override
  Future<void> saveAll(List<EmojiRecord> all) async {
    _checkNotDisposed();
    await isar.writeTxn(() async {
      await isar.emojiRecordEntitys.clear();
      await isar.emojiRecordEntitys.putAll(all.map(toEntity).toList());
    });
  }

  /// dispose済みまたはIsar閉じている場合にエラーを投げる
  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('Cannot use a disposed IsarEmojiStore');
    }
    if (!isar.isOpen) {
      throw StateError('Cannot use IsarEmojiStore with a closed Isar instance');
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    if (ownsIsar) {
      await isar.close();
    }
  }
}
