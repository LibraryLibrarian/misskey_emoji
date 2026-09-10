import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

import '../helpers/fake_emoji_source.dart';

const _record = EmojiRecord(
  name: '保存済み',
  aliases: ['別名'],
  category: '分類',
  url: 'https://example.com/emoji.png',
  localOnly: false,
  isSensitive: true,
  allowRoleIds: [],
);

void main() {
  late Directory directory;
  final stores = <EmojiStore>[];
  final catalogs = <PersistentEmojiCatalog>[];

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('emoji_catalog_');
  });
  tearDown(() async {
    for (final catalog in catalogs) {
      await catalog.dispose();
    }
    catalogs.clear();
    for (final store in stores) {
      await store.dispose();
    }
    stores.clear();
    await directory.delete(recursive: true);
  });

  Future<EmojiStore> open() async {
    final store = await openEmojiStoreForServer(
      Uri.parse('https://example.com'),
      directory: directory.path,
    );
    stores.add(store);
    return store;
  }

  test('実DBとカタログを再生成してもTTL内はレコードと同期時刻を復元し再取得しない', () async {
    final source = FakeEmojiSource(records: [_record]);
    final store = await open();
    final catalog = PersistentEmojiCatalog(source: source, store: store);
    catalogs.add(catalog);
    await catalog.sync();
    expect(source.callCount, 1);
    final saved = await store.load();
    expect(saved.syncedAt, isNotNull);
    await catalog.dispose();

    final restartedSource = FakeEmojiSource();
    final restartedStore = await open();
    final restarted = PersistentEmojiCatalog(
      source: restartedSource,
      store: restartedStore,
    );
    catalogs.add(restarted);
    final restored = await restartedStore.load();
    expect(restored.records.single.name, _record.name);
    expect(restored.records.single.aliases, _record.aliases);
    expect(restored.syncedAt, saved.syncedAt);

    await restarted.sync();
    expect(restartedSource.callCount, isZero);
    expect(restarted.get(_record.name)?.url, _record.url);
    expect(restarted.get('別名')?.name, _record.name);
    expect((await restartedStore.load()).syncedAt, saved.syncedAt);
  });

  test('ownsStoreがfalseならカタログの破棄後も実ストアを操作できる', () async {
    final store = await open();
    final catalog = PersistentEmojiCatalog(
      source: FakeEmojiSource(),
      store: store,
      ownsStore: false,
    );
    catalogs.add(catalog);
    await catalog.dispose();
    final time = DateTime.utc(2026);
    await store.save([_record], syncedAt: time);
    expect((await store.load()).records.single.name, _record.name);
    expect(await store.count(), 1);
    await store.dispose();
    await expectLater(Future.sync(store.load), throwsStateError);
  });

  test('ownsStoreがtrueならカタログの破棄後は実ストアの全操作がStateErrorになる', () async {
    final store = await open();
    final catalog = PersistentEmojiCatalog(
      source: FakeEmojiSource(),
      store: store,
      ownsStore: true,
    );
    catalogs.add(catalog);
    await catalog.sync();
    await catalog.dispose();
    await expectLater(Future.sync(store.load), throwsStateError);
    await expectLater(
      store.save([], syncedAt: DateTime.utc(2026)),
      throwsStateError,
    );
    await expectLater(store.clear(), throwsStateError);
    await expectLater(store.count(), throwsStateError);
    await expectLater(store.sizeInBytes(), throwsStateError);
  });
}
