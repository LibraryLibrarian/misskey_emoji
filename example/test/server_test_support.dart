import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:misskey_emoji_example/features/server/models/server_context.dart';
import 'package:misskey_emoji_example/features/server/models/server_entry.dart';
import 'package:misskey_emoji_example/features/server/services/server_manager.dart';

class TestEmojiSource implements EmojiSource {
  TestEmojiSource(this.records);

  final List<EmojiRecord> records;
  int callCount = 0;

  @override
  Future<List<EmojiRecord>> fetchAll() async {
    callCount++;
    return records;
  }
}

class TestEmojiStore implements EmojiStore {
  TestEmojiStore({this.size, this.sizeError, this.disposeError});

  final int? size;
  final Object? sizeError;
  final Object? disposeError;
  List<EmojiRecord> _records = [];
  DateTime? _syncedAt;
  int disposeCount = 0;

  @override
  Future<void> clear() async {
    _records = [];
    _syncedAt = null;
  }

  @override
  Future<int> count() async => _records.length;

  @override
  Future<void> dispose() async {
    disposeCount++;
    final error = disposeError;
    if (error != null) throw error;
  }

  @override
  Future<EmojiSnapshot> load() async =>
      EmojiSnapshot(records: _records, syncedAt: _syncedAt);

  @override
  Future<void> save(List<EmojiRecord> all, {required DateTime syncedAt}) async {
    _records = List.of(all);
    _syncedAt = syncedAt;
  }

  @override
  Future<int?> sizeInBytes() async {
    final error = sizeError;
    if (error != null) throw error;
    return size;
  }
}

ServerContextFactory testContextFactory({
  required TestEmojiSource Function(ServerEntry entry) sourceFor,
  TestEmojiStore Function(ServerEntry entry)? storeFor,
}) {
  return (entry) async {
    final source = sourceFor(entry);
    final store = storeFor?.call(entry) ?? TestEmojiStore();
    final catalog = PersistentEmojiCatalog(
      source: source,
      store: store,
      ttl: const Duration(minutes: 30),
    );
    final client = MisskeyClient(
      config: MisskeyClientConfig(baseUrl: Uri.parse(entry.url)),
    );
    return ServerContext(
      client: client,
      source: source,
      store: store,
      catalog: catalog,
      resolver: MisskeyEmojiResolver(catalog),
    );
  };
}

EmojiRecord testEmoji(String name) => EmojiRecord(
  name: name,
  aliases: const [],
  url: 'https://example.com/$name.png',
  localOnly: false,
  isSensitive: false,
  allowRoleIds: const [],
);
