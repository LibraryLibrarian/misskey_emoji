import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji_example/features/emoji_browser/presentation/emoji_browser_page.dart';
import 'package:misskey_emoji_example/features/server/models/server_entry.dart';
import 'package:misskey_emoji_example/features/server/presentation/server_detail_page.dart';
import 'package:misskey_emoji_example/features/server/services/server_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'server_test_support.dart';

void main() {
  const server = ServerEntry(name: 'テスト', url: 'https://example.com');

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'servers_v1': jsonEncode([server.toJson()]),
      'last_server_key_v1': server.key,
    });
  });

  testWidgets('起動と設定画面からの復帰はTTLを尊重して同期する', (tester) async {
    final source = TestEmojiSource(const []);
    final manager = ServerManager(
      contextFactory: testContextFactory(sourceFor: (_) => source),
    );

    await tester.pumpWidget(
      MaterialApp(home: EmojiBrowserPage(manager: manager)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(source.callCount, 1);

    expect(source.callCount, 1);

    await tester.tap(find.byTooltip('設定'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(source.callCount, 1);
  });

  testWidgets('同期ボタンとプル更新は強制同期する', (tester) async {
    final source = TestEmojiSource(const []);
    final manager = ServerManager(
      contextFactory: testContextFactory(sourceFor: (_) => source),
    );

    await tester.pumpWidget(
      MaterialApp(home: EmojiBrowserPage(manager: manager)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(source.callCount, 1);

    await tester.tap(find.byTooltip('同期'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(source.callCount, 2);

    await tester.drag(
      find.descendant(
        of: find.byType(RefreshIndicator),
        matching: find.byType(ListView),
      ),
      const Offset(0, 300),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(source.callCount, 3);
  });

  testWidgets('容量がnullのとき計測対象なしを表示する', (tester) async {
    final manager = ServerManager(
      contextFactory: testContextFactory(
        sourceFor: (_) => TestEmojiSource(const []),
      ),
    );
    await manager.init();

    await tester.pumpWidget(
      MaterialApp(
        home: ServerDetailPage(manager: manager, server: server),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('計測対象なし'), findsOneWidget);
  });
}
