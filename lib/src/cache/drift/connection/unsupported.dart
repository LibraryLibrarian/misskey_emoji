import '../../emoji_store.dart';

/// このプラットフォームでは永続ストアを提供しない
Future<EmojiStore> openStore({
  required String directory,
  required String databaseName,
}) async {
  await Future<void>.value();
  throw UnsupportedError('このプラットフォームの絵文字ストアは未対応です');
}
