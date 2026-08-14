[日本語](README.ja.md)

# misskey_emoji

[![Pub package](https://img.shields.io/pub/v/misskey_emoji.svg)](https://pub.dev/packages/misskey_emoji)
[![GitHub License](https://img.shields.io/badge/License-BSD-green.svg)](LICENSE)

A Flutter library for caching and resolving Misskey MFM (Markup For Misskey) emoji metadata with persistent storage and efficient retrieval.

## Features

- Emoji metadata caching with persistent storage using Isar database (names, URLs, attributes, etc.)
- Efficient emoji resolution and retrieval by shortcode
- In-memory and persistent catalog implementations
- Search functionality for emojis by shortcode and keywords
- Integration with Misskey API for emoji synchronization
- Cross-platform support (iOS/Android)
- Optimized for MFM (Markup For Misskey) emoji handling
- **Note**: Image data caching should be implemented on the application side using libraries like `cached_network_image`

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  misskey_emoji: ^2.0.0-beta.1
```

## Quick Start

`EmojiSource` is the catalog's only synchronization boundary. Use `MisskeyClientEmojiSource` for a Misskey server, or implement `EmojiSource.fetchAll()` to provide records from another source or a test double.

### Basic Usage

```dart
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:misskey_client/misskey_client.dart';

// Create a typed Misskey client
final client = MisskeyClient(
  config: MisskeyClientConfig(baseUrl: Uri.parse('https://misskey.io')),
);

// Adapt MisskeyClient to the EmojiSource interface
final emojiSource = MisskeyClientEmojiSource(client);

// Create persistent catalog with Isar storage
final catalog = PersistentEmojiCatalog(
  source: emojiSource,
  store: IsarEmojiStore(),
);

// Sync emoji metadata from server
await catalog.sync();

// Get emoji metadata by shortcode
final emoji = await catalog.get(':custom_emoji:');
if (emoji != null) {
  print('Emoji URL: ${emoji.url}');
  print('Is animated: ${emoji.animated}');
}

// Search emojis
final searchResults = await EmojiSearch.search(
  catalog,
  query: 'smile',
  options: EmojiSearchOptions(limit: 10),
);
```

### Using Emoji Resolver

```dart
// Create resolver for emoji resolution
final resolver = MisskeyEmojiResolver(catalog);

// Resolve emoji metadata from shortcode
final emojiImage = await resolver.resolve(':custom_emoji:');
if (emojiImage != null) {
  print('Resolved emoji URL: ${emojiImage.url}');
  print('Is animated: ${emojiImage.animated}');
  print('Is sensitive: ${emojiImage.isSensitive}');
}
```

### Displaying Emojis with Image Caching

```dart
// For displaying emojis with image caching, implement on the application side
import 'package:cached_network_image/cached_network_image.dart';

Widget buildEmoji(String shortcode) {
  return FutureBuilder<EmojiImage?>(
    future: resolver.resolve(shortcode),
    builder: (context, snapshot) {
      if (snapshot.hasData && snapshot.data != null) {
        return CachedNetworkImage(
          imageUrl: snapshot.data!.url.toString(),
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Icon(Icons.error),
        );
      }
      return Icon(Icons.emoji_emotions);
    },
  );
}
```

### In-Memory Catalog (for temporary usage)

```dart
// For cases where persistent storage is not needed
final inMemoryCatalog = InMemoryEmojiCatalog(
  source: emojiSource,
);

await inMemoryCatalog.sync();
final emoji = await inMemoryCatalog.get(':example:');
```

## Resource Management

When you finish using catalogs or stores, call `dispose()` to release resources.

### Basic cleanup

```dart
final isar = await openEmojiIsarForServer(
  Uri.parse('https://misskey.io'),
  directory: '/path/to/isar',
);
final store = IsarEmojiStore(isar);
final catalog = PersistentEmojiCatalog(source: emojiSource, store: store);

try {
  await catalog.sync();
  final emoji = catalog.get(':custom_emoji:');
} finally {
  await catalog.dispose(); // store.dispose() is called internally
  await isar.close(); // close Isar explicitly when you own it
}
```

### Error handling

```dart
final catalog = PersistentEmojiCatalog(
  source: emojiSource,
  store: store,
  onSyncError: (error, stackTrace) {
    // Log errors for debugging or monitoring
    print('Emoji sync failed: $error');
    // You can also send to error tracking service
  },
);
```

### Riverpod integration examples

#### Basic: Single provider with owned Isar

```dart
@riverpod
class EmojiCatalogNotifier extends _$EmojiCatalogNotifier {
  @override
  FutureOr<PersistentEmojiCatalog> build() async {
    // Create a typed Misskey client and emoji source
    final client = MisskeyClient(
      config: MisskeyClientConfig(baseUrl: Uri.parse('https://misskey.io')),
    );
    final emojiSource = MisskeyClientEmojiSource(client);
    
    // Create store with owned Isar instance
    final appDir = await getApplicationDocumentsDirectory();
    final isar = await openEmojiIsarForServer(
      Uri.parse('https://misskey.io'),
      directory: appDir.path,
    );
    final store = IsarEmojiStore(isar, ownsIsar: true);
    final catalog = PersistentEmojiCatalog(
      source: emojiSource,
      store: store,
      onSyncError: (error, stackTrace) {
        debugPrint('Emoji sync failed: $error');
      },
    );

    // Dispose resources when provider is disposed
    ref.onDispose(() async {
      await catalog.dispose(); // closes Isar because ownsIsar is true
    });

    await catalog.sync();
    return catalog;
  }
}
```

#### Recommended: Shared Isar instance for better resource management

```dart
// Shared Isar instance provider (reusable across multiple catalogs)
@riverpod
Future<Isar> emojiIsar(Ref ref) async {
  final appDir = await getApplicationDocumentsDirectory();
  final isar = await openEmojiIsarForServer(
    Uri.parse('https://misskey.io'),
    directory: appDir.path,
  );
  
  // Close Isar when the app is disposed
  ref.onDispose(() async {
    await isar.close();
  });
  
  return isar;
}

// Emoji catalog provider using shared Isar
@riverpod
class EmojiCatalogNotifier extends _$EmojiCatalogNotifier {
  @override
  FutureOr<PersistentEmojiCatalog> build() async {
    final client = MisskeyClient(
      config: MisskeyClientConfig(baseUrl: Uri.parse('https://misskey.io')),
    );
    final emojiSource = MisskeyClientEmojiSource(client);
    
    // Use shared Isar instance (ownsIsar: false is default)
    final isar = await ref.watch(emojiIsarProvider.future);
    final store = IsarEmojiStore(isar); // Isar lifecycle managed by emojiIsarProvider
    final catalog = PersistentEmojiCatalog(
      source: emojiSource,
      store: store,
      onSyncError: (error, stackTrace) {
        // Send to error tracking service (e.g., Sentry, Firebase Crashlytics)
        debugPrint('Emoji sync failed: $error');
      },
    );

    ref.onDispose(() async {
      await catalog.dispose(); // Only disposes catalog, Isar remains open
    });

    await catalog.sync();
    return catalog;
  }
}

// Usage in your widget
class EmojiPickerWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(emojiCatalogNotifierProvider);
    
    return catalogAsync.when(
      data: (catalog) {
        final emoji = catalog.get(':custom_emoji:');
        return emoji != null ? Text('Found: ${emoji.name}') : Text('Not found');
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

## API Reference

For detailed API documentation, please refer to the documentation on pub.dev.

## License

This project is published by 司書 (LibraryLibrarian) under the 3-Clause BSD License. For details, please see the [LICENSE](LICENSE) file.

## Related Links

- [pub.dev Package](https://pub.dev/packages/misskey_emoji)
- [Misskey Documentation](https://misskey-hub.net/en/)
