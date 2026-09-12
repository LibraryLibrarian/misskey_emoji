import 'dart:convert';

import '../cache/drift/connection/shared.dart' as connection;
import '../cache/emoji_store.dart';

/// 指定したMisskeyサーバー用の絵文字キャッシュストアを開く
///
/// [directory]にサーバーごとに分離されたDBファイルを作成する。
/// 保存先は呼び出し側で選択する。同じ正規化済み絶対ディレクトリと
/// サーバー由来のファイル名の組を二重に開くと[StateError]を送出する。
/// オープン中の並行呼び出しも拒否する。返されたストアのdispose()完了後は
/// 再度開ける（dispose()が失敗した場合も登録を解除する）。
///
/// 二重オープンの管理は呼び出し元isolate内に限る。別isolateからのオープンや、
/// シンボリックリンクなど別のパス表現による同一ファイルへのアクセスは検出しない。
Future<EmojiStore> openEmojiStoreForServer(
  Uri baseUrl, {
  required String directory,
}) => connection.openStore(
  directory: directory,
  databaseName:
      'misskey_emoji_${serverKeyFromBaseUrl(baseUrl)}_${_originHash(baseUrl)}',
);

String _originHash(Uri baseUrl) {
  final hashInput = jsonEncode([
    baseUrl.scheme.toLowerCase(),
    baseUrl.host.toLowerCase(),
    baseUrl.hasPort ? baseUrl.port : null,
  ]);
  // FNV-1aの32ビット値を使用し、実行環境に依存するString.hashCodeは使わない。
  // 8桁の有限ハッシュなので衝突の数学的な排除はできない。
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(hashInput)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

/// サーバーごとに分離されたキャッシュキーを生成するためのユーティリティ
String serverKeyFromBaseUrl(Uri baseUrl) {
  final scheme = baseUrl.scheme.toLowerCase();
  final host = baseUrl.host.toLowerCase();
  final port = baseUrl.hasPort ? baseUrl.port.toString() : '';
  final raw = [scheme, host, port].where((e) => e.isNotEmpty).join('_');
  final safe = raw.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return safe.replaceAll(RegExp(r'_+'), '_');
}
