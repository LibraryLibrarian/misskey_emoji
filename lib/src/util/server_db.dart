import 'package:isar/isar.dart';

import '../cache/isar_emoji_store.dart';

/// サーバーごとに分離されたIsar名を生成するためのユーティリティ
String serverKeyFromBaseUrl(Uri baseUrl) {
  final scheme = baseUrl.scheme.toLowerCase();
  final host = baseUrl.host.toLowerCase();
  final port = baseUrl.hasPort ? baseUrl.port.toString() : '';
  final raw = [scheme, host, port].where((e) => e.isNotEmpty).join('_');
  final safe = raw.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return safe.replaceAll(RegExp(r'_+'), '_');
}

/// 指定したMisskeyサーバー用に、絵文字キャッシュ専用のIsarを開く
///
/// - Isarのnameをサーバー単位で変えることで、キャッシュの棲み分けを行う
Future<Isar> openEmojiIsarForServer(Uri baseUrl, {required String directory}) {
  final key = serverKeyFromBaseUrl(baseUrl);
  final dbName = 'misskey_emoji_$key';
  return Isar.open(
    [EmojiRecordEntitySchema],
    directory: directory,
    name: dbName,
  );
}
