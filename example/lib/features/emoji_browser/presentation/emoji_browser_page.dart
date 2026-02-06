import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../server/models/server_entry.dart';
import '../../server/presentation/settings_drawer.dart';
import '../../server/services/server_manager.dart';
import 'widgets/emoji_grid.dart';
import 'widgets/emoji_search_bar.dart';

class EmojiBrowserPage extends StatefulWidget {
  const EmojiBrowserPage({super.key});

  @override
  State<EmojiBrowserPage> createState() => _EmojiBrowserPageState();
}

class _EmojiBrowserPageState extends State<EmojiBrowserPage> {
  late final TextEditingController _serverNameController;
  late final TextEditingController _serverUrlController;
  late final TextEditingController _searchController;
  final ServerManager _manager = ServerManager();
  bool _isAppBarVisible = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _serverNameController = TextEditingController();
    _serverUrlController = TextEditingController(text: 'https://misskey.io');
    _searchController = TextEditingController();
    unawaited(_manager.init());
  }

  @override
  void dispose() {
    _serverNameController.dispose();
    _serverUrlController.dispose();
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

  Future<void> _handleAddServer() async {
    final name = _serverNameController.text.trim();
    final url = _serverUrlController.text.trim();
    final ok = await _manager.addServer(name, url);
    if (ok) {
      _serverNameController.clear();
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
          drawer: SettingsDrawer(
            servers: _manager.servers,
            selectedKey: _manager.selectedKey,
            onSelectServer: _manager.selectServer,
            serverNameController: _serverNameController,
            serverUrlController: _serverUrlController,
            onAddServer: _handleAddServer,
            onRemoveSelected: _manager.removeSelectedServer,
            onTestConnection: _manager.testConnection,
            onSync: _manager.sync,
            onClearCache: _manager.clearCache,
            statusText: _manager.status,
            lastSync: _manager.lastSync,
            isSyncing: _manager.isSyncing,
          ),
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _handleScrollNotification(notification);
              return false;
            },
            child: EmojiGrid(
              catalog: _manager.currentContext?.catalog,
              resolver: _manager.currentContext?.resolver,
              onSync: _manager.sync,
              searchText: _searchText,
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: EmojiSearchBar(
                controller: _searchController,
                onChanged: (text) {
                  setState(() => _searchText = text.trim());
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
