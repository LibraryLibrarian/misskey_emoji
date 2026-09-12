import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji_example/features/server/models/server_entry.dart';
import 'package:misskey_emoji_example/features/server/services/server_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'server_test_support.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ServerManager', () {
    test('同じサーバーへの並行切替は初期化を共有する', () async {
      const serverA = ServerEntry(name: 'A', url: 'https://a.example.com');
      const serverB = ServerEntry(name: 'B', url: 'https://b.example.com');
      SharedPreferences.setMockInitialValues({
        'servers_v1': jsonEncode([serverA.toJson(), serverB.toJson()]),
        'last_server_key_v1': serverA.key,
      });
      final startedB = Completer<void>();
      final completeB = Completer<void>();
      final factoryCalls = <String, int>{};
      final manager = ServerManager(
        contextFactory: (entry) async {
          factoryCalls.update(
            entry.key,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
          if (entry.key == serverB.key) {
            startedB.complete();
            await completeB.future;
          }
          return testContextFactory(
            sourceFor: (_) => TestEmojiSource(const []),
          )(entry);
        },
      );
      addTearDown(manager.close);

      await manager.init();
      final first = manager.selectServer(serverB.key);
      await startedB.future;
      final second = manager.selectServer(serverB.key);
      completeB.complete();

      await Future.wait([first, second]);
      expect(manager.selectedKey, serverB.key);
      expect(factoryCalls[serverB.key], 1);
    });

    test('ストア容量の値、計測対象なし、取得失敗を区別する', () async {
      const valueServer = ServerEntry(
        name: '値',
        url: 'https://value.example.com',
      );
      const noneServer = ServerEntry(
        name: 'なし',
        url: 'https://none.example.com',
      );
      const errorServer = ServerEntry(
        name: '失敗',
        url: 'https://error.example.com',
      );
      final stores = <String, TestEmojiStore>{
        valueServer.key: TestEmojiStore(size: 123),
        noneServer.key: TestEmojiStore(),
        errorServer.key: TestEmojiStore(sizeError: StateError('読み取り失敗')),
      };
      final manager = ServerManager(
        contextFactory: testContextFactory(
          sourceFor: (_) => TestEmojiSource(const []),
          storeFor: (entry) => stores[entry.key]!,
        ),
      );
      addTearDown(manager.close);

      await manager.addServer(valueServer.name, valueServer.url);
      await manager.addServer(noneServer.name, noneServer.url);
      await manager.addServer(errorServer.name, errorServer.url);

      expect(await manager.getDatabaseSizeFor(valueServer.key), 123);
      expect(await manager.getDatabaseSizeFor(noneServer.key), isNull);
      expect(await manager.getDatabaseSizeFor(errorServer.key), -1);
    });

    test('close失敗時は削除対象の設定とコンテキストを保持する', () async {
      const server = ServerEntry(name: 'A', url: 'https://a.example.com');
      final store = TestEmojiStore(disposeError: StateError('close失敗'));
      final manager = ServerManager(
        contextFactory: testContextFactory(
          sourceFor: (_) => TestEmojiSource(const []),
          storeFor: (_) => store,
        ),
      );

      await manager.addServer(server.name, server.url);
      await expectLater(manager.removeServer(server.key), throwsStateError);
      expect(manager.servers.map((entry) => entry.key), contains(server.key));
      expect(await manager.getEmojiCountFor(server.key), 0);
    });

    test('サーバーごとに異なるキャッシュを表示する', () async {
      const serverA = ServerEntry(name: 'A', url: 'https://a.example.com');
      const serverB = ServerEntry(name: 'B', url: 'https://b.example.com');
      final sources = <String, TestEmojiSource>{
        serverA.key: TestEmojiSource([testEmoji('a')]),
        serverB.key: TestEmojiSource([testEmoji('b')]),
      };
      final manager = ServerManager(
        contextFactory: testContextFactory(
          sourceFor: (entry) => sources[entry.key]!,
        ),
      );
      addTearDown(manager.close);

      await manager.addServer(serverA.name, serverA.url);
      await manager.sync(force: true);
      await manager.addServer(serverB.name, serverB.url);
      await manager.sync(force: true);

      expect(manager.currentContext!.catalog.get('b'), isNotNull);
      expect(manager.currentContext!.catalog.get('a'), isNull);
      await manager.selectServer(serverA.key);
      expect(manager.currentContext!.catalog.get('a'), isNotNull);
      expect(manager.currentContext!.catalog.get('b'), isNull);
    });
  });
}
