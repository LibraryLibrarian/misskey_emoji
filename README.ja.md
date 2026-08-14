[English](README.md) | 日本語

# misskey_emoji

[![Pub package](https://img.shields.io/pub/v/misskey_emoji.svg)](https://pub.dev/packages/misskey_emoji)
[![GitHub License](https://img.shields.io/badge/License-BSD-green.svg)](LICENSE)

Misskey MFM（Markup For Misskey）絵文字のメタデータのキャッシュと解決を行うFlutterライブラリ。永続化ストレージと効率的な取得機能を提供します。

## 概要

- Isarデータベースを使用した絵文字メタデータの永続化キャッシュ（名前、URL、属性など）
- 効率的な絵文字解決と取得機能
- インメモリおよび永続化カタログの実装
- ショートコードとキーワードによる絵文字検索機能
- Misskey APIとの統合による絵文字同期
- MFM（Markup For Misskey）絵文字処理の最適化
- **注意**: 画像データのキャッシュは`cached_network_image`などのライブラリを使用してアプリケーション側で実装してください

## 導入

`pubspec.yaml`ファイルに以下を追加してください：

```yaml
dependencies:
  misskey_emoji: ^2.0.0-beta.1
```

## 利用方法

`EmojiSource`がカタログ同期の唯一の境界です。Misskeyサーバーには`MisskeyClientEmojiSource`を使用し、別の取得元やテスト用実装が必要な場合は`EmojiSource.fetchAll()`を実装してください。

### 基本的な使用方法

```dart
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:misskey_client/misskey_client.dart';

// 型付きMisskeyクライアントを作成
final client = MisskeyClient(
  config: MisskeyClientConfig(baseUrl: Uri.parse('https://misskey.io')),
);

// MisskeyClientをEmojiSourceインターフェースへ接続
final emojiSource = MisskeyClientEmojiSource(client);

// Isarストレージを使用した永続化カタログを作成
final catalog = PersistentEmojiCatalog(
  source: emojiSource,
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

### 絵文字リゾルバーの使用

```dart
// 絵文字解決用のリゾルバーを作成
final resolver = MisskeyEmojiResolver(catalog);

// ショートコードから絵文字メタデータを解決
final emojiImage = await resolver.resolve(':custom_emoji:');
if (emojiImage != null) {
  print('解決された絵文字URL: ${emojiImage.url}');
  print('アニメーション: ${emojiImage.animated}');
  print('センシティブ: ${emojiImage.isSensitive}');
}
```

### 画像キャッシュ付きの絵文字表示

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

### インメモリカタログ（一時的な使用）

```dart
// 永続化ストレージが不要な場合
final inMemoryCatalog = InMemoryEmojiCatalog(
  source: emojiSource,
);

await inMemoryCatalog.sync();
final emoji = await inMemoryCatalog.get(':example:');
```

## リソース管理

カタログやストアの利用後は、`dispose()`を呼び出してリソースを解放するようにしてください

### 基本的なクリーンアップ

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
  await catalog.dispose(); // store.dispose() が内部で呼ばれる
  await isar.close(); // 所有している場合は明示的にクローズ
}
```

### エラーハンドリング

```dart
final catalog = PersistentEmojiCatalog(
  source: emojiSource,
  store: store,
  onSyncError: (error, stackTrace) {
    // デバッグや監視のためのエラーログ
    print('絵文字同期失敗: $error');
    // エラー追跡サービスに送信することも可能
  },
);
```

### Riverpodとの統合

#### 単一プロバイダーでIsarを所有

```dart
@riverpod
class EmojiCatalogNotifier extends _$EmojiCatalogNotifier {
  @override
  FutureOr<PersistentEmojiCatalog> build() async {
    // 型付きMisskeyクライアントと絵文字ソースを作成
    final client = MisskeyClient(
      config: MisskeyClientConfig(baseUrl: Uri.parse('https://misskey.io')),
    );
    final emojiSource = MisskeyClientEmojiSource(client);
    
    // 所有権を持つIsarインスタンスでストアを作成
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
        debugPrint('絵文字同期失敗: $error');
      },
    );

    // プロバイダーがdisposeされた時にリソースを解放
    ref.onDispose(() async {
      await catalog.dispose(); // ownsIsarがtrueならIsarもクローズされる
    });

    await catalog.sync();
    return catalog;
  }
}
```

#### Isarインスタンスを共有してリソース管理を改善（基本的にこちらを推奨）

```dart
// 共有Isarインスタンスプロバイダー（複数のカタログで再利用可能）
@riverpod
Future<Isar> emojiIsar(Ref ref) async {
  final appDir = await getApplicationDocumentsDirectory();
  final isar = await openEmojiIsarForServer(
    Uri.parse('https://misskey.io'),
    directory: appDir.path,
  );
  
  // アプリ終了時にIsarをクローズ
  ref.onDispose(() async {
    await isar.close();
  });
  
  return isar;
}

// 共有Isarを使用する絵文字カタログプロバイダー
@riverpod
class EmojiCatalogNotifier extends _$EmojiCatalogNotifier {
  @override
  FutureOr<PersistentEmojiCatalog> build() async {
    final client = MisskeyClient(
      config: MisskeyClientConfig(baseUrl: Uri.parse('https://misskey.io')),
    );
    final emojiSource = MisskeyClientEmojiSource(client);
    
    // 共有Isarインスタンスを使用（ownsIsar: falseがデフォルト）
    final isar = await ref.watch(emojiIsarProvider.future);
    final store = IsarEmojiStore(isar); // IsarのライフサイクルはemojiIsarProviderが管理
    final catalog = PersistentEmojiCatalog(
      source: emojiSource,
      store: store,
      onSyncError: (error, stackTrace) {
        // エラー追跡サービスに送信（例: Sentry、Firebase Crashlytics）
        debugPrint('絵文字同期失敗: $error');
      },
    );

    ref.onDispose(() async {
      await catalog.dispose(); // カタログのみをdispose、Isarは開いたまま
    });

    await catalog.sync();
    return catalog;
  }
}

// ウィジェットでの使用例
class EmojiPickerWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(emojiCatalogNotifierProvider);
    
    return catalogAsync.when(
      data: (catalog) {
        final emoji = catalog.get(':custom_emoji:');
        return emoji != null ? Text('見つかりました: ${emoji.name}') : Text('見つかりません');
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('エラー: $error'),
    );
  }
}
```

## APIリファレンス

詳細なAPIドキュメントについては、pub.devのドキュメントを参照してください。

## ライセンス

このプロジェクトは司書(LibraryLibrarian)によって、3-Clause BSD Licenseの下で公開されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。

## リンク

- [pub.dev パッケージ](https://pub.dev/packages/misskey_emoji)
- [Misskey ドキュメント](https://misskey-hub.net/ja/)
