[日本語](README.ja.md)

# misskey_emoji

[![Pub package](https://img.shields.io/pub/v/misskey_emoji.svg)](https://pub.dev/packages/misskey_emoji)
[![GitHub License](https://img.shields.io/badge/License-BSD-green.svg)](LICENSE)

A Flutter library for caching, resolving, and searching Misskey MFM (Markup For Misskey) emoji metadata.

## Features

- Persistent caching of emoji metadata (names, URLs, attributes, and more)
- Efficient emoji resolution and retrieval by shortcode
- In-memory and persistent catalog implementations
- Search functionality for emojis by shortcode and keywords
- Integration with the Misskey API for emoji synchronization
- Cross-platform support (iOS/Android)
- Optimized for MFM (Markup For Misskey) emoji handling

### Image caching

This package stores emoji **metadata only**. The consuming application is responsible for caching and displaying image bytes, usually through an `ImageProvider`-based package such as `cached_network_image`.

This separation is intentional:

- Flutter displays images through `ImageProvider`; implementing a second image pipeline here would duplicate Flutter's image-cache integration.
- Applications commonly already cache avatars and media. A separate emoji cache would duplicate those cache layers and double disk use.
- Only the application can choose an appropriate storage budget and eviction policy. For example, misskey.io's 13,569 emoji would use about 270 MB at an assumed average of 20 KB per image.
- Storing image BLOBs with metadata would inflate the metadata database and slow its full reads and writes.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  misskey_emoji: ^2.0.0-beta.1
```

This release requires Dart `>=3.10.0 <4.0.0` and Flutter `>=3.38.0`.

## Quick Start

`EmojiSource` is the catalog's only synchronization boundary. Use `MisskeyClientEmojiSource` for a Misskey server, or implement `EmojiSource.fetchAll()` to provide records from another source or a test double.

### Basic Usage

```dart
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

Future<void> main() async {
  // Create a typed Misskey client.
  final client = MisskeyClient(
    config: MisskeyClientConfig(baseUrl: Uri.parse('https://misskey.io')),
  );
  final emojiSource = MisskeyClientEmojiSource(client);

  // The application chooses the directory for its persistent cache.
  final store = await openEmojiStoreForServer(
    Uri.parse('https://misskey.io'),
    directory: '/path/to/emoji-cache',
  );
  final catalog = PersistentEmojiCatalog(source: emojiSource, store: store);

  try {
    await catalog.sync();

    // EmojiCatalog.get is synchronous.
    final emoji = catalog.get(':custom_emoji:');
    if (emoji != null) {
      print('Emoji URL: ${emoji.url}');
      print('Is animated: ${emoji.animated}');
    }

    final searchResults = EmojiSearch(catalog).query('smile', limit: 10);
    print('Found ${searchResults.length} emojis');
  } finally {
    // PersistentEmojiCatalog owns its store by default.
    await catalog.dispose();
  }
}
```

Use `EmojiSearch(catalog).queryAdvanced(text, options: ...)` when you need an `EmojiSearchOptions` value, such as a category or a non-default search mode.

### Using Emoji Resolver

```dart
// Create a resolver for emoji resolution.
final resolver = MisskeyEmojiResolver(catalog);

// Resolve emoji metadata from a shortcode.
final emojiImage = await resolver.resolve(':custom_emoji:');
if (emojiImage != null) {
  print('Resolved emoji URL: ${emojiImage.url}');
  print('Is animated: ${emojiImage.animated}');
  print('Is sensitive: ${emojiImage.isSensitive}');
}
```

### Displaying Emojis with Image Caching

```dart
// Image display and image caching belong to the application.
import 'package:cached_network_image/cached_network_image.dart';

Widget buildEmoji(String shortcode) {
  return FutureBuilder<EmojiImage?>(
    future: resolver.resolve(shortcode),
    builder: (context, snapshot) {
      if (snapshot.hasData && snapshot.data != null) {
        return CachedNetworkImage(
          imageUrl: snapshot.data!.url.toString(),
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        );
      }
      return const Icon(Icons.emoji_emotions);
    },
  );
}
```

### In-Memory Catalog

```dart
// Use this when persistent storage is not needed.
final inMemoryCatalog = InMemoryEmojiCatalog(source: emojiSource);

await inMemoryCatalog.sync();
final emoji = inMemoryCatalog.get(':example:');
```

## Resource Management

Call `dispose()` when a catalog or store is no longer needed. A `PersistentEmojiCatalog` owns its store by default, so disposing a single catalog also disposes the store.

### Basic cleanup

```dart
final store = await openEmojiStoreForServer(
  Uri.parse('https://misskey.io'),
  directory: '/path/to/emoji-cache',
);
final catalog = PersistentEmojiCatalog(source: emojiSource, store: store);

try {
  await catalog.sync();
  final emoji = catalog.get(':custom_emoji:');
} finally {
  await catalog.dispose();
}
```

### Error handling

```dart
final catalog = PersistentEmojiCatalog(
  source: emojiSource,
  store: store,
  onSyncError: (error, stackTrace) {
    // Log errors for debugging or monitoring.
    print('Emoji sync failed: $error');
    // You can also send the error to an error-tracking service.
  },
);
```

### Multiple server caches

Opening one persistent cache for each server creates one database instance per server. Drift emits a debug diagnostic when the same database class is instantiated multiple times. If opening multiple server caches is intentional, call `suppressMultipleDatabaseWarning()` before opening them.

```dart
suppressMultipleDatabaseWarning();
```

This changes a process-global Drift diagnostic flag. It also suppresses multiple-database warnings for databases owned by the consuming application, so only opt in when that trade-off is appropriate.

### Riverpod integration examples

The following snippets assume the usual Riverpod, Flutter, and `path_provider` imports and code generation setup.

#### Single catalog

Leave `ownsStore` at its default (`true`) when a catalog is the only user of its store. Dispose only the catalog.

```dart
@riverpod
class EmojiCatalogNotifier extends _$EmojiCatalogNotifier {
  @override
  FutureOr<PersistentEmojiCatalog> build() async {
    final client = MisskeyClient(
      config: MisskeyClientConfig(baseUrl: Uri.parse('https://misskey.io')),
    );
    final emojiSource = MisskeyClientEmojiSource(client);
    final appDir = await getApplicationDocumentsDirectory();
    final store = await openEmojiStoreForServer(
      Uri.parse('https://misskey.io'),
      directory: appDir.path,
    );
    final catalog = PersistentEmojiCatalog(
      source: emojiSource,
      store: store,
      onSyncError: (error, stackTrace) {
        debugPrint('Emoji sync failed: $error');
      },
    );

    ref.onDispose(() async {
      await catalog.dispose();
    });

    await catalog.sync();
    return catalog;
  }
}
```

#### Shared store for multiple catalogs

When multiple catalogs share one store, set `ownsStore: false` on every catalog. A separate provider owns and disposes the shared store.

```dart
@riverpod
Future<EmojiStore> emojiStore(Ref ref) async {
  final appDir = await getApplicationDocumentsDirectory();
  final store = await openEmojiStoreForServer(
    Uri.parse('https://misskey.io'),
    directory: appDir.path,
  );

  ref.onDispose(() async {
    await store.dispose();
  });
  return store;
}

@riverpod
class EmojiCatalogNotifier extends _$EmojiCatalogNotifier {
  @override
  FutureOr<PersistentEmojiCatalog> build() async {
    final client = MisskeyClient(
      config: MisskeyClientConfig(baseUrl: Uri.parse('https://misskey.io')),
    );
    final emojiSource = MisskeyClientEmojiSource(client);
    final store = await ref.watch(emojiStoreProvider.future);
    final catalog = PersistentEmojiCatalog(
      source: emojiSource,
      store: store,
      ownsStore: false,
      onSyncError: (error, stackTrace) {
        debugPrint('Emoji sync failed: $error');
      },
    );

    ref.onDispose(() async {
      await catalog.dispose();
    });

    await catalog.sync();
    return catalog;
  }
}
```

## Persistent-store build configuration

The native SQLite dependency is supplied by `sqlite3` 3.x build hooks. During a build, the hooks download prebuilt binaries from GitHub Releases and verify them with SHA-256. Build environments therefore need network access, unless the consuming application configures an alternative source.

`hooks.user_defines` is controlled by the consuming application because it is the root package that owns the build configuration. For example, SQLCipher, the operating system's SQLite library, and an internal binary mirror must be configured in the application's own `pubspec.yaml`; this package cannot provide defaults for them.

```yaml
# The consuming application's pubspec.yaml
hooks:
  user_defines:
    sqlite3:
      source: system
```

Consult the `sqlite3` build-hook documentation for the available source-specific settings.

## Migrating from 1.x cache files

Version 2 uses a differently named `.sqlite` database for each server: `misskey_emoji_<serverKey>_<hash8>.sqlite`. Old cache files therefore do not affect 2.0.0 behavior. There is no deletion utility: these files are only cache data, and the next `sync()` fetches fresh metadata (about 848 KiB gzipped once for misskey.io). Leaving them in place only consumes disk space; measured usage for misskey.io was 7.2 MB per server.

If you choose to remove old cache files, do so only after every old 1.x Isar instance has been closed. The directory is the directory that your application passed to `openEmojiIsarForServer` in 1.x. Only these files are candidates:

```text
<directory>/misskey_emoji_*.isar
<directory>/misskey_emoji_*.isar-lck
```

The `.isar` file was initially preallocated to 1 MiB and its matching lock file was 16 KiB; both remain after the old store is closed. Filter by the `misskey_emoji_` prefix before deleting anything. An application may use the same directory for its own unrelated Isar databases, which must not be removed. The package does not migrate these files because they are disposable cache data; copying them would retain the old dependency or hardcode its naming convention.

## API Reference

For detailed API documentation, please refer to the documentation on pub.dev.

## License

This project is published by 司書 (LibraryLibrarian) under the 3-Clause BSD License. For details, please see the [LICENSE](LICENSE) file.

## Related Links

- [pub.dev Package](https://pub.dev/packages/misskey_emoji)
- [Misskey Documentation](https://misskey-hub.net/en/)
