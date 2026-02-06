import 'package:isar_community/isar.dart';
import 'package:misskey_api_core/misskey_api_core.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

class ServerContext {
  final Isar isar;
  final MisskeyHttpClient http;
  final MisskeyEmojiApi api;
  final IsarEmojiStore store;
  final PersistentEmojiCatalog catalog;
  final MisskeyEmojiResolver resolver;

  const ServerContext({
    required this.isar,
    required this.http,
    required this.api,
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
