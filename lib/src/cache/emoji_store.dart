import '../models/emoji_record.dart';

/// 永続化用の抽象絵文字ストア
abstract class EmojiStore {
  /// すべての絵文字レコードを読み込む
  Future<List<EmojiRecord>> loadAll();

  /// 渡された一覧で既存の絵文字レコードをすべて置き換える
  Future<void> saveAll(List<EmojiRecord> all);

  /// ストアが使用するリソースをクリーンアップ
  ///
  /// ストアが不要になった時に呼び出す
  /// 実装クラスによっては、データベース接続のクリーンアップなどを行う
  Future<void> dispose();
}
