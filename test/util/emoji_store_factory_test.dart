import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory directory;
  final baseUrl = Uri.parse('https://example.com');
  final stores = <EmojiStore>[];

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('emoji_factory_');
  });
  tearDown(() async {
    for (final store in stores) {
      await store.dispose();
    }
    stores.clear();
    await directory.delete(recursive: true);
  });

  Future<EmojiStore> open(Uri uri, {String? path}) async {
    final store = await openEmojiStoreForServer(
      uri,
      directory: path ?? directory.path,
    );
    stores.add(store);
    return store;
  }

  test('正規化された同一パスとoriginの二重オープンを拒否する', () async {
    await open(baseUrl);
    await expectLater(
      open(
        Uri.parse('https://EXAMPLE.com:443/path?query=1'),
        path: p.relative(p.join(directory.path, 'unused', '..')),
      ),
      throwsStateError,
    );
  });

  test('並行オープンのうち一方だけが成功する', () async {
    final opening = open(baseUrl);
    await expectLater(open(baseUrl), throwsStateError);
    await opening;
  });

  test('dispose後に再オープンしてレコードと同期時刻を復元する', () async {
    final store = await open(baseUrl);
    final time = DateTime.utc(2026, 9, 10, 0, 0, 0, 123, 456);
    const record = EmojiRecord(
      name: '保存済み',
      aliases: ['別名'],
      url: 'https://example.com/a.png',
      localOnly: false,
      isSensitive: true,
      allowRoleIds: [],
    );
    await store.save([record], syncedAt: time);
    expect(await store.sizeInBytes(), greaterThan(0));
    await store.dispose();
    final restored = await open(baseUrl);
    final snapshot = await restored.load();
    expect(snapshot.records.single.name, record.name);
    expect(snapshot.records.single.aliases, record.aliases);
    expect(snapshot.syncedAt, time);
  });

  test('serverKeyFromBaseUrlが受け付けるURIでストアを開ける', () async {
    final urls = [
      Uri.parse('ftp://example.com'),
      Uri.parse('wss://example.com'),
      Uri.parse('mailto:user@example.com'),
      Uri.parse('file:///tmp/server'),
      Uri.parse('example.com/path'),
      Uri.parse('https:/path-only'),
    ];

    for (final url in urls) {
      final store = await open(url);
      await store.dispose();
      stores.remove(store);
    }
  });

  test('schemeまたはportだけが異なるURIは別ファイルを使用する', () async {
    final first = await open(Uri.parse('https://example.com'));
    await first.save([], syncedAt: DateTime.utc(2026));
    await first.dispose();
    stores.remove(first);

    final second = await open(Uri.parse('http://example.com'));
    expect((await second.load()).syncedAt, isNull);
    await second.dispose();
    stores.remove(second);

    final third = await open(Uri.parse('https://example.com:8443'));
    expect((await third.load()).syncedAt, isNull);
    await third.dispose();
    stores.remove(third);

    final files = await directory
        .list()
        .map((file) => p.basename(file.path))
        .where((name) => name.endsWith('.sqlite'))
        .toList();
    expect(files, hasLength(3));
    expect(files.toSet(), hasLength(3));
  });

  test('旧キーが衝突するホストでも異なるファイルを使用する', () async {
    final firstUrl = Uri.parse('https://a-b.example');
    final secondUrl = Uri.parse('https://a_b.example');
    expect(serverKeyFromBaseUrl(firstUrl), serverKeyFromBaseUrl(secondUrl));
    final first = await open(firstUrl);
    final second = await open(secondUrl);
    final time = DateTime.utc(2026);
    await first.save([], syncedAt: time);
    expect((await second.load()).syncedAt, isNull);
    final files = await directory
        .list()
        .map((file) => p.basename(file.path))
        .toList();
    expect(files.where((name) => name.endsWith('.sqlite')), hasLength(2));
    expect(
      files.where((name) => name.endsWith('.sqlite')),
      everyElement(
        matches(r'^misskey_emoji_https_a_b_example_[0-9a-f]{8}\.sqlite$'),
      ),
    );
  });

  test('オープン失敗後は登録を残さず再試行できる', () async {
    final blockedPath = p.join(directory.path, 'blocked');
    final blocker = await File(blockedPath).writeAsString('ディレクトリではない');
    await expectLater(
      open(baseUrl, path: blockedPath),
      throwsA(isA<FileSystemException>()),
    );
    await blocker.delete();
    final store = await open(baseUrl, path: blockedPath);
    expect(await store.count(), isZero);
  });

  test('警告抑制は明示的に呼んだ場合だけグローバル状態を変更する', () async {
    final previous = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    try {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
      await open(baseUrl);
      expect(driftRuntimeOptions.dontWarnAboutMultipleDatabases, isFalse);
      suppressMultipleDatabaseWarning();
      expect(driftRuntimeOptions.dontWarnAboutMultipleDatabases, isTrue);
    } finally {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = previous;
    }
  });
}
