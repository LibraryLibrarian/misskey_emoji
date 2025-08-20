import '../models/emoji_record.dart';

/// 絵文字の参照・同期を行う読み取り専用カタログのインターフェース
abstract class EmojiCatalog {
  /// サーバーや永続ストアから内部インデックスを同期
  Future<void> sync({bool force = false});

  /// 指定したショートコードに対応する[EmojiRecord]を返す（なければnull）
  EmojiRecord? get(String shortcode);

  /// 正規化済みショートコードからレコードへの不変マップを返す
  Map<String, EmojiRecord> snapshot();
}
