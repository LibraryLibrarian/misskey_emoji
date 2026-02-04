# misskey_emoji

[![Pub package](https://img.shields.io/pub/v/misskey_emoji.svg)](https://pub.dev/packages/misskey_emoji)
[![GitHub License](https://img.shields.io/badge/License-BSD-green.svg)](LICENSE)

A Flutter library for caching and resolving Misskey MFM (Markup For Misskey) emoji metadata with persistent storage and efficient retrieval.

[日本語](#日本語)

### Features

- Emoji metadata caching with persistent storage using Isar database (names, URLs, attributes, etc.)
- Efficient emoji resolution and retrieval by shortcode
- In-memory and persistent catalog implementations
- Search functionality for emojis by shortcode and keywords
- Integration with Misskey API for emoji synchronization
- Cross-platform support (iOS/Android)
- Optimized for MFM (Markup For Misskey) emoji handling
- **Note**: Image data caching should be implemented on the application side using libraries like `cached_network_image`

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  misskey_emoji: ^0.0.1-beta
```

### Quick Start

#### Basic Usage

```dart
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:misskey_api_core/misskey_api_core.dart';

// Create HTTP client for Misskey API
final httpClient = MisskeyHttpClient(
  config: MisskeyApiConfig(baseUrl: Uri.parse('https://misskey.io')),
);

// Create emoji API client
final emojiApi = MisskeyEmojiApi(httpClient);

// Create persistent catalog with Isar storage
final catalog = PersistentEmojiCatalog(
  api: emojiApi,
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

#### Using Emoji Resolver

```dart
// Create resolver for emoji resolution
final resolver = MisskeyEmojiResolver(catalog: catalog);

// Resolve emoji metadata from shortcode
final emojiImage = await resolver.resolve(':custom_emoji:');
if (emojiImage != null) {
  print('Resolved emoji URL: ${emojiImage.url}');
  print('Is animated: ${emojiImage.animated}');
  print('Is sensitive: ${emojiImage.isSensitive}');
}
```

#### Displaying Emojis with Image Caching

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

#### In-Memory Catalog (for temporary usage)

```dart
// For cases where persistent storage is not needed
final inMemoryCatalog = InMemoryEmojiCatalog(
  api: emojiApi,
  host: 'misskey.io',
);

await inMemoryCatalog.sync();
final emoji = await inMemoryCatalog.get(':example:');
```

### API Reference

For detailed API documentation, please refer to the documentation on pub.dev.

### License

This project is published by 司書 (LibraryLibrarian) under the 3-Clause BSD License. For details, please see the [LICENSE](LICENSE) file.

### Related Links

- [pub.dev Package](https://pub.dev/packages/misskey_emoji)
- [Misskey Documentation](https://misskey-hub.net/en/)

---

## Japanese

Misskey MFM（Markup For Misskey）絵文字のメタデータのキャッシュと解決を行うFlutterライブラリ。永続化ストレージと効率的な取得機能を提供します。

### 内容

- Isarデータベースを使用した絵文字メタデータの永続化キャッシュ（名前、URL、属性など）
- 効率的な絵文字解決と取得機能
- インメモリおよび永続化カタログの実装
- ショートコードとキーワードによる絵文字検索機能
- Misskey APIとの統合による絵文字同期
- MFM（Markup For Misskey）絵文字処理の最適化
- **注意**: 画像データのキャッシュは`cached_network_image`などのライブラリを使用してアプリケーション側で実装してください

### インストール

`pubspec.yaml`ファイルに以下を追加してください：

```yaml
dependencies:
  misskey_emoji: ^0.0.1-beta
```

### クイックスタート

#### 基本的な使用方法

```dart
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:misskey_api_core/misskey_api_core.dart';

// Misskey API用のHTTPクライアントを作成
final httpClient = MisskeyHttpClient(
  config: MisskeyApiConfig(baseUrl: Uri.parse('https://misskey.io')),
);

// 絵文字APIクライアントを作成
final emojiApi = MisskeyEmojiApi(httpClient);

// Isarストレージを使用した永続化カタログを作成
final catalog = PersistentEmojiCatalog(
  api: emojiApi,
  store: IsarEmojiStore(),
);

// サーバーから絵文字メタデータを同期
await catalog.sync();

// ショートコードで絵文字メタデータを取得
final emoji = await catalog.get(':custom_emoji:');
if (emoji != null) {
  print('絵文字URL: ${emoji.url}');
  print('アニメーション: ${emoji.animated}');
}

// 絵文字を検索
final searchResults = await EmojiSearch.search(
  catalog,
  query: 'smile',
  options: EmojiSearchOptions(limit: 10),
);
```

#### 絵文字リゾルバーの使用

```dart
// 絵文字解決用のリゾルバーを作成
final resolver = MisskeyEmojiResolver(catalog: catalog);

// ショートコードから絵文字メタデータを解決
final emojiImage = await resolver.resolve(':custom_emoji:');
if (emojiImage != null) {
  print('解決された絵文字URL: ${emojiImage.url}');
  print('アニメーション: ${emojiImage.animated}');
  print('センシティブ: ${emojiImage.isSensitive}');
}
```

#### 画像キャッシュ付きの絵文字表示

```dart
// 画像キャッシュ付きで絵文字を表示する場合は、アプリケーション側で実装
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

#### インメモリカタログ（一時的な使用）

```dart
// 永続化ストレージが不要な場合
final inMemoryCatalog = InMemoryEmojiCatalog(
  api: emojiApi,
  host: 'misskey.io',
);

await inMemoryCatalog.sync();
final emoji = await inMemoryCatalog.get(':example:');
```

### APIリファレンス

詳細なAPIドキュメントについては、pub.devのドキュメントを参照してください。

### ライセンス

このプロジェクトは司書(LibraryLibrarian)によって、3-Clause BSD Licenseの下で公開されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。

### リンク

- [pub.dev パッケージ](https://pub.dev/packages/misskey_emoji)
- [Misskey ドキュメント](https://misskey-hub.net/ja/)
