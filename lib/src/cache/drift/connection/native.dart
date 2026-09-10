import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../../emoji_store.dart';
import '../drift_emoji_store.dart';
import '../emoji_database.dart';

/// ファイルの作成とSQLiteの実行をバックグラウンド接続へ委譲する
DatabaseConnection openConnection({
  required String directory,
  required String databaseName,
}) {
  final file = File(p.join(directory, '$databaseName.sqlite'));
  return DatabaseConnection.delayed(
    Future(() async {
      await file.parent.create(recursive: true);
      return NativeDatabase.createBackgroundConnection(file);
    }),
  );
}

// トップレベルの状態は呼び出し元isolate内に限られる。
final _openFiles = <String>{};
final _openingFiles = <String>{};

/// 同じファイルへの並行オープンを防ぎ、成功した接続だけを登録する
Future<EmojiStore> openStore({
  required String directory,
  required String databaseName,
}) async {
  final normalizedDirectory = p.normalize(p.absolute(directory));
  final path = p.join(normalizedDirectory, '$databaseName.sqlite');
  if (_openFiles.contains(path) || !_openingFiles.add(path)) {
    throw StateError('同じ絵文字キャッシュは既に開かれているか、オープン中です');
  }
  final database = EmojiDatabase(
    openConnection(
      directory: normalizedDirectory,
      databaseName: databaseName,
    ),
  );
  try {
    // Driftの接続は遅延評価されるため、スキーマの初期化まで待ってから登録する。
    await database.customSelect('SELECT 1').get();
    _openFiles.add(path);
    return DriftEmojiStore(
      database,
      readSizeInBytes: () => databaseSizeInBytes(path),
      onDisposed: () => _openFiles.remove(path),
    );
  } on Object {
    try {
      await database.close();
    } on Object {
      // クリーンアップの失敗で元のオープンエラーを隠さない。
    }
    rethrow;
  } finally {
    _openingFiles.remove(path);
  }
}

/// DB本体と存在するWAL・SHMの論理ファイル長を合算する
Future<int> databaseSizeInBytes(String path) async {
  var size = await File(path).length();
  for (final suffix in ['-wal', '-shm']) {
    try {
      size += await File('$path$suffix').length();
    } on FileSystemException catch (error) {
      // 存在しない補助ファイルだけを無視し、権限などのI/Oエラーは伝播する。
      if (error.osError?.errorCode != 2) rethrow;
    }
  }
  return size;
}
