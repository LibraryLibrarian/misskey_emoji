import 'dart:async';

import 'package:misskey_emoji/src/models/emoji_record.dart';
import 'package:misskey_emoji/src/source/emoji_source.dart';

class FakeEmojiSource implements EmojiSource {
  FakeEmojiSource({
    this.records = const [],
    this.error,
    this.waitFor,
  });

  final List<EmojiRecord> records;
  final Exception? error;
  final Future<void>? waitFor;
  int callCount = 0;

  @override
  Future<List<EmojiRecord>> fetchAll() async {
    callCount++;
    await waitFor;
    final fetchError = error;
    if (fetchError != null) throw fetchError;
    return List<EmojiRecord>.unmodifiable(records);
  }
}
