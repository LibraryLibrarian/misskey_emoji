import 'package:flutter_test/flutter_test.dart';

import 'package:misskey_emoji/misskey_emoji.dart';

void main() {
  test('公開APIがエクスポートされている', () {
    expect(EmojiRecord, isNotNull);
    expect(MisskeyEmojiResolver, isNotNull);
    expect(InMemoryEmojiCatalog, isNotNull);
  });
}
