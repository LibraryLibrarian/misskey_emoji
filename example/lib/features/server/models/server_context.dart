import 'package:isar_community/isar.dart';
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

class ServerContext {
  final Isar isar;
  final MisskeyClient client;
  final EmojiSource source;
  final IsarEmojiStore store;
  final PersistentEmojiCatalog catalog;
  final MisskeyEmojiResolver resolver;

  const ServerContext({
    required this.isar,
    required this.client,
    required this.source,
    required this.store,
    required this.catalog,
    required this.resolver,
  });

  Future<void> close() async {
    try {
      await isar.close();
    } catch (_) {}
  }
}
