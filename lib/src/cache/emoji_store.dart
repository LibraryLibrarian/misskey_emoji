import '../models/emoji_record.dart';

abstract class EmojiStore {
  Future<List<EmojiRecord>> loadAll();
  Future<void> saveAll(List<EmojiRecord> all);
}


