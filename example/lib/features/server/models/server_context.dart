import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

class ServerContext {
  final MisskeyClient client;
  final EmojiSource source;
  final EmojiStore store;
  final PersistentEmojiCatalog catalog;
  final MisskeyEmojiResolver resolver;

  const ServerContext({
    required this.client,
    required this.source,
    required this.store,
    required this.catalog,
    required this.resolver,
  });

  Future<void> close() => catalog.dispose();
}
