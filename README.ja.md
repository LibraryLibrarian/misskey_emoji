[English](README.md) | 日本語

# misskey_emoji

[![Pub package](https://img.shields.io/pub/v/misskey_emoji.svg)](https://pub.dev/packages/misskey_emoji)
[![GitHub License](https://img.shields.io/badge/License-BSD-green.svg)](LICENSE)

Misskey MFM（Markup For Misskey）絵文字のメタデータをキャッシュ、解決、検索するFlutterライブラリです。

## 概要

- 絵文字メタデータ（名前、URL、属性など）の永続化キャッシュ
- ショートコードによる効率的な絵文字解決と取得
- インメモリおよび永続化カタログの実装
- ショートコードとキーワードによる絵文字検索
- Misskey APIとの統合による絵文字同期
- iOS/Androidのクロスプラットフォーム対応
- MFM（Markup For Misskey）絵文字処理の最適化

### 画像キャッシュ

本パッケージが保存するのは絵文字の**メタデータのみ**です。画像バイト列のキャッシュと表示は、通常は`cached_network_image`などの`ImageProvider`ベースのパッケージを用いて、利用側アプリケーションが担当してください。

この責務分担には次の理由があります。

- Flutterの画像表示は`ImageProvider`を経由します。本パッケージが別の画像パイプラインを実装すると、Flutterの画像キャッシュとの連携を重複して実装することになります。
- アプリケーションはアバターやメディアのキャッシュをすでに持つことが多く、絵文字用の別キャッシュを持つとキャッシュ層とディスク使用量が二重になります。
- 容量上限とエビクション方針を決められるのはアプリケーションだけです。たとえばmisskey.ioの13,569件を平均20 KBの画像と仮定すると、約270 MBになります。
- メタデータと同じDBに画像BLOBを保存するとファイルが肥大化し、メタデータの全件読み書きも遅くなります。

## 導入

`pubspec.yaml`ファイルに以下を追加してください。

```yaml
dependencies:
  misskey_emoji: ^2.0.0-beta.1
```

このリリースにはDart `>=3.10.0 <4.0.0`およびFlutter `>=3.38.0`が必要です。

## 利用方法

`EmojiSource`がカタログ同期の唯一の境界です。Misskeyサーバーには`MisskeyClientEmojiSource`を使用し、別の取得元やテスト用実装が必要な場合は`EmojiSource.fetchAll()`を実装してください。

### 基本的な使用方法

```dart
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

Future<void> main() async {
  // 型付きMisskeyクライアントを作成します。
  final client = MisskeyClient(
    config: MisskeyClientConfig(baseUrl: Uri.parse('https://misskey.io')),
  );
  final emojiSource = MisskeyClientEmojiSource(client);

  // 永続キャッシュの保存先はアプリケーションが選択します。
  final store = await openEmojiStoreForServer(
    Uri.parse('https://misskey.io'),
    directory: '/path/to/emoji-cache',
  );
  final catalog = PersistentEmojiCatalog(source: emojiSource, store: store);

  try {
    await catalog.sync();

    // EmojiCatalog.getは同期メソッドです。
    final emoji = catalog.get(':custom_emoji:');
    if (emoji != null) {
      print('絵文字URL: ${emoji.url}');
      print('アニメーション: ${emoji.animated}');
    }

    final searchResults = EmojiSearch(catalog).query('smile', limit: 10);
    print('${searchResults.length}件の絵文字が見つかりました');
  } finally {
    // PersistentEmojiCatalogは既定でストアを所有します。
    await catalog.dispose();
  }
}
```

カテゴリや検索モードなどの`EmojiSearchOptions`を指定する場合は、`EmojiSearch(catalog).queryAdvanced(text, options: ...)`を使用してください。

### 絵文字リゾルバーの使用

```dart
// 絵文字解決用のリゾルバーを作成します。
final resolver = MisskeyEmojiResolver(catalog);

// ショートコードから絵文字メタデータを解決します。
final emojiImage = await resolver.resolve(':custom_emoji:');
if (emojiImage != null) {
  print('解決された絵文字URL: ${emojiImage.url}');
  print('アニメーション: ${emojiImage.animated}');
  print('センシティブ: ${emojiImage.isSensitive}');
}
```

### 画像キャッシュ付きの絵文字表示

```dart
// 画像の表示とキャッシュはアプリケーション側で実装します。
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

### インメモリカタログ

```dart
// 永続ストレージが不要な場合に使用します。
final inMemoryCatalog = InMemoryEmojiCatalog(source: emojiSource);

await inMemoryCatalog.sync();
final emoji = inMemoryCatalog.get(':example:');
```

## リソース管理

カタログまたはストアが不要になったら`dispose()`を呼び出してください。`PersistentEmojiCatalog`は既定でストアを所有するため、単一のカタログを破棄するとストアも破棄されます。

### 基本的なクリーンアップ

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

### エラーハンドリング

```dart
final catalog = PersistentEmojiCatalog(
  source: emojiSource,
  store: store,
  onSyncError: (error, stackTrace) {
    // デバッグや監視のためにエラーを記録します。
    print('絵文字同期失敗: $error');
    // エラー追跡サービスへ送信することもできます。
  },
);
```

### 複数サーバーのキャッシュ

サーバーごとに永続キャッシュを開くと、サーバーごとにDBインスタンスが作成されます。同じDBクラスを複数回生成すると、Driftはデバッグ時に診断メッセージを出します。複数サーバーのキャッシュを同時に開くことが意図した動作である場合は、開く前に`suppressMultipleDatabaseWarning()`を呼び出してください。

```dart
suppressMultipleDatabaseWarning();
```

この関数はDriftのプロセス全体に効く診断フラグを変更します。そのため利用側アプリケーション自身のDBに対する複数DB警告も抑制されます。この影響を許容できる場合だけ明示的に呼び出してください。

### Riverpodとの統合

以下の例では、通常のRiverpod、Flutter、`path_provider`のimportとコード生成設定が済んでいることを前提にしています。

#### 単一カタログ

1つのカタログだけがストアを使用する場合は、`ownsStore`を既定値（`true`）のまま使用してください。破棄するのはカタログだけです。

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
        debugPrint('絵文字同期失敗: $error');
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

#### 複数カタログでストアを共有する場合

複数のカタログで1つのストアを共有する場合は、すべてのカタログに`ownsStore: false`を指定してください。共有ストアは別のプロバイダーが所有して破棄します。

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
        debugPrint('絵文字同期失敗: $error');
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

## 永続ストアのビルド設定

ネイティブSQLite依存は`sqlite3` 3.xのbuild hooksにより提供されます。build hooksはビルド時にGitHub Releasesからprebuiltバイナリをダウンロードし、SHA-256で検証します。そのため、別の取得元を利用する設定がない限り、ビルド環境にはネットワークアクセスが必要です。

`hooks.user_defines`を設定するのは利用側アプリケーションです。利用側アプリケーションはbuild設定を所有するroot packageだからです。SQLCipher、OS同梱SQLite、社内ミラーからのバイナリ取得は、利用側アプリケーション自身の`pubspec.yaml`で設定してください。本パッケージから既定値を提供することはできません。

```yaml
# 利用側アプリケーションのpubspec.yaml
hooks:
  user_defines:
    sqlite3:
      source: system
```

利用可能な取得元ごとの設定は`sqlite3`のbuild-hookドキュメントを参照してください。

## 1.xのキャッシュファイルからの移行

2.0.0ではサーバーごとに`misskey_emoji_<serverKey>_<hash8>.sqlite`という異なる名前の`.sqlite`データベースを使用するため、古いキャッシュファイルは2.0.0の動作に影響しません。削除ユーティリティは提供しません。古いファイルはキャッシュデータにすぎず、次の`sync()`でメタデータが再取得されます（misskey.ioではgzip圧縮で約848 KiBを1回）。残しておいた場合の影響はディスク使用量だけで、misskey.ioでの実測は1サーバーあたり7.2 MBです。

削除する場合は、1.xの古いIsarインスタンスをすべて閉じた後に行ってください。`<directory>`は、1.xでアプリケーションが`openEmojiIsarForServer`へ渡していたディレクトリです。削除候補は次のファイルだけです。

```text
<directory>/misskey_emoji_*.isar
<directory>/misskey_emoji_*.isar-lck
```

`.isar`ファイルは初期状態で1 MiBが事前確保され、対応するロックファイルは16 KiBです。どちらも旧ストアを閉じた後も残ります。削除前には必ず`misskey_emoji_`プレフィックスで絞り込んでください。アプリケーションが同じディレクトリで独自のIsarデータベースを使っている場合、それらを削除してはいけません。これらは再取得可能なキャッシュなので、移行のために古い依存を維持したり、旧ファイル名の規約をライブラリに固定したりはしません。

## APIリファレンス

詳細なAPIドキュメントについては、pub.devのドキュメントを参照してください。

## ライセンス

このプロジェクトは司書(LibraryLibrarian)によって、3-Clause BSD Licenseの下で公開されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。

## リンク

- [pub.dev パッケージ](https://pub.dev/packages/misskey_emoji)
- [Misskey ドキュメント](https://misskey-hub.net/ja/)
