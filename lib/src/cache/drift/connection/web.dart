import '../../emoji_store.dart';

/// 将来のWeb接続実装に向けたスタブ
Future<EmojiStore> openStore({
  required String directory,
  required String databaseName,
}) async {
  await Future<void>.value();
  throw UnimplementedError('Web用の絵文字ストアは未実装です');
}
