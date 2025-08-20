import '../models/emoji_record.dart';

abstract class EmojiCatalog {
  Future<void> sync({bool force = false});
  EmojiRecord? get(String shortcode);
  Map<String, EmojiRecord> snapshot();
}


