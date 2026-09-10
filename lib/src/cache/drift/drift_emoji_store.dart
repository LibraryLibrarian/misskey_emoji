import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/emoji_record.dart';
import '../emoji_store.dart';
import 'emoji_database.dart';

/// Drift接続を所有する絵文字ストア
class DriftEmojiStore implements EmojiStore {
  DriftEmojiStore(this.database, {this.readSizeInBytes, this.onDisposed});

  final EmojiDatabase database;

  /// ファイルを持つ接続でのみ指定する容量取得処理
  final Future<int> Function()? readSizeInBytes;

  /// 接続の終了に失敗した場合も呼び出す登録解除処理
  final void Function()? onDisposed;

  Future<void>? _disposing;

  void _checkOpen() {
    if (_disposing != null) {
      throw StateError('破棄済みの絵文字ストアは操作できません');
    }
  }

  @override
  Future<EmojiSnapshot> load() {
    _checkOpen();
    return database.transaction(() async {
      final query = database.select(database.emojiRecords)
        ..orderBy([(table) => OrderingTerm.asc(table.rowId)]);
      final rows = await query.get();
      final metadata = await database
          .select(database.syncMetadata)
          .getSingleOrNull();
      return EmojiSnapshot(
        records: [
          for (final row in rows)
            EmojiRecord(
              name: row.name,
              aliases: (jsonDecode(row.aliases) as List<dynamic>)
                  .cast<String>(),
              category: row.category,
              url: row.url,
              localOnly: row.localOnly,
              isSensitive: row.isSensitive,
              allowRoleIds: (jsonDecode(row.allowRoleIds) as List<dynamic>)
                  .cast<String>(),
            ),
        ],
        syncedAt: metadata?.lastSyncedAt,
      );
    });
  }

  @override
  Future<void> save(List<EmojiRecord> all, {required DateTime syncedAt}) async {
    _checkOpen();
    // 更新だけでは最初のrowidが残るため、Dart側で最後の出現位置へ移す。
    final recordsByName = <String, EmojiRecord>{};
    for (final record in all) {
      recordsByName.remove(record.name);
      recordsByName[record.name] = record;
    }
    final rows = [
      for (final record in recordsByName.values)
        EmojiRecordsCompanion.insert(
          name: record.name,
          aliases: jsonEncode(record.aliases),
          category: Value(record.category),
          url: record.url,
          localOnly: record.localOnly,
          isSensitive: record.isSensitive,
          allowRoleIds: jsonEncode(record.allowRoleIds),
        ),
    ];
    await database.transaction(() async {
      await database.delete(database.emojiRecords).go();
      await database.batch(
        (batch) => batch.insertAll(database.emojiRecords, rows),
      );
      await database.delete(database.syncMetadata).go();
      await database
          .into(database.syncMetadata)
          .insert(
            SyncMetadataCompanion.insert(
              id: const Value(1),
              lastSyncedAt: syncedAt,
            ),
          );
    });
  }

  @override
  Future<void> clear() async {
    _checkOpen();
    await database.transaction(() async {
      await database.delete(database.emojiRecords).go();
      await database.delete(database.syncMetadata).go();
    });
  }

  @override
  Future<int> count() async {
    _checkOpen();
    final count = database.emojiRecords.name.count();
    final query = database.selectOnly(database.emojiRecords)
      ..addColumns([count]);
    return (await query.getSingle()).read(count)!;
  }

  @override
  Future<int?> sizeInBytes() async {
    _checkOpen();
    return readSizeInBytes?.call();
  }

  @override
  Future<void> dispose() => _disposing ??= _dispose();

  Future<void> _dispose() async {
    try {
      await database.close();
    } finally {
      onDisposed?.call();
    }
  }
}

/// 複数サーバーのキャッシュを同時に開く場合の明示的な警告抑制
///
/// Driftのプロセス全体の診断フラグを変更する。利用側アプリケーション自身の
/// データベースに対する正当な警告も抑制される点に注意する。
void suppressMultipleDatabaseWarning() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
}
