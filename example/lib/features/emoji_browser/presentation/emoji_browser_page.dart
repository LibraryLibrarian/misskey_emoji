import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../server/models/server_entry.dart';
import '../../server/presentation/settings_page.dart';
import '../../server/services/server_manager.dart';
import 'widgets/emoji_grid.dart';
import 'widgets/emoji_search_bar.dart';

class EmojiBrowserPage extends StatefulWidget {
  const EmojiBrowserPage({super.key});

  @override
  State<EmojiBrowserPage> createState() => _EmojiBrowserPageState();
}

class _EmojiBrowserPageState extends State<EmojiBrowserPage> {
  late final TextEditingController _searchController;
  final ServerManager _manager = ServerManager();
  bool _isAppBarVisible = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    unawaited(_manager.init().then((_) => _autoSyncIfNeeded()));
  }

  Future<void> _autoSyncIfNeeded() async {
    final catalog = _manager.currentContext?.catalog;
    if (catalog == null) return;

    // カタログが空の場合は自動同期
    final snapshot = catalog.snapshot();
    if (snapshot.isEmpty && !_manager.isSyncing) {
      await _manager.sync();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    unawaited(_manager.close());
    _manager.dispose();
    super.dispose();
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      final direction = notification.direction;
      if (direction == ScrollDirection.reverse && _isAppBarVisible) {
        setState(() => _isAppBarVisible = false);
      } else if (direction == ScrollDirection.forward && !_isAppBarVisible) {
        setState(() => _isAppBarVisible = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        final selectedServer = _manager.selectedServer ??
            (_manager.servers.isNotEmpty
                ? _manager.servers.first
                : const ServerEntry(name: '未選択', url: ''));

        return Scaffold(
          appBar: _isAppBarVisible
              ? AppBar(
                  title: Row(
                    children: [
                      const Icon(Icons.emoji_emotions, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Misskey Emoji'),
                            Text(
                              selectedServer.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.sync),
                      onPressed: _manager.isSyncing ||
                              _manager.currentContext?.catalog == null
                          ? null
                          : _manager.sync,
                      tooltip: '同期',
                    ),
                  ],
                  bottom: _manager.isSyncing
                      ? const PreferredSize(
                          preferredSize: Size.fromHeight(4),
                          child: LinearProgressIndicator(),
                        )
                      : null,
                )
              : null,
          body: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  _handleScrollNotification(notification);
                  return false;
                },
                child: EmojiGrid(
                  catalog: _manager.currentContext?.catalog,
                  resolver: _manager.currentContext?.resolver,
                  onSync: _manager.sync,
                  searchText: _searchText,
                  catalogVersion:
                      _manager.catalogVersionFor(_manager.selectedKey),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: FloatingActionButton(
                          onPressed: () => _navigateToSettings(context),
                          tooltip: '設定',
                          child: const Icon(Icons.settings),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: EmojiSearchBar(
                          controller: _searchController,
                          onChanged: (text) {
                            setState(() => _searchText = text.trim());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _navigateToSettings(BuildContext context) async {
    final hadServer = _manager.selectedServer != null;
    final previousKey = _manager.selectedKey;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(manager: _manager),
      ),
    );

    // 設定画面から戻った後の自動同期処理
    final hasServerNow = _manager.selectedServer != null;
    final catalog = _manager.currentContext?.catalog;
    final serverChanged = _manager.selectedKey != previousKey;

    if (!hasServerNow || catalog == null) return;

    if (!hadServer) {
      // サーバーが新規に追加された場合
      unawaited(_manager.sync());
      return;
    }

    if (serverChanged) {
      // アクティブサーバーが変更された場合は必ず同期
      unawaited(_manager.sync());
      return;
    }

    // 同じサーバーでもカタログが空なら同期
    final snapshot = catalog.snapshot();
    if (snapshot.isEmpty) {
      unawaited(_manager.sync());
    }
  }
}
