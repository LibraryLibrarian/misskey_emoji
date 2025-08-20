import '../models/emoji_record.dart';

/// 永続化用の抽象絵文字ストア
abstract class EmojiStore {
  /// すべての絵文字レコードを読み込む
  Future<List<EmojiRecord>> loadAll();

  /// 渡された一覧で既存の絵文字レコードをすべて置き換える
  Future<void> saveAll(List<EmojiRecord> all);
}
