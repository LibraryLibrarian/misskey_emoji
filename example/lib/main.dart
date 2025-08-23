import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:misskey_api_core/misskey_api_core.dart';
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MisskeyEmojiExampleApp());
}

class MisskeyEmojiExampleApp extends StatelessWidget {
  const MisskeyEmojiExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Misskey Emoji Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  // 入力用
  late final TextEditingController _serverNameController;
  late final TextEditingController _serverUrlController;
  int _tabIndex = 0;

  // サーバー定義と選択状態
  List<ServerEntry> _servers = [];
  String? _selectedKey;

  // サーバーごとの実体
  final Map<String, ServerContext> _contexts = {};

  String _status = '未初期化';
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _serverNameController = TextEditingController();
    _serverUrlController = TextEditingController(text: 'https://misskey.io');
    _init();
  }

  @override
  void dispose() {
    _serverNameController.dispose();
    _serverUrlController.dispose();
    for (final c in _contexts.values) {
      unawaited(c.close());
    }
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _status = '初期化中...');
    final prefs = await SharedPreferences.getInstance();
    final loaded = prefs.getString('servers_v1');
    final last = prefs.getString('last_server_key_v1');
    List<ServerEntry> servers = [];
    if (loaded != null && loaded.isNotEmpty) {
      final list =
          (json.decode(loaded) as List?)?.cast<Map<String, dynamic>>() ??
              const [];
      servers = list.map((j) => ServerEntry.fromJson(j)).toList();
      // 同一キー（=同一サーバー）の重複を除去
      if (servers.isNotEmpty) {
        final seen = <String>{};
        servers = servers.where((e) => seen.add(e.key)).toList();
      }
    }
    if (servers.isEmpty) {
      servers = [ServerEntry(name: 'misskey.io', url: 'https://misskey.io')];
      await prefs.setString(
          'servers_v1', json.encode(servers.map((e) => e.toJson()).toList()));
    }
    String selectedKey = last ?? servers.first.key;
    final selectedEntry = servers.firstWhere((e) => e.key == selectedKey,
        orElse: () => servers.first);
    await _ensureContextFor(selectedEntry);
    setState(() {
      _servers = servers;
      _selectedKey = selectedEntry.key;
      _status = '準備完了';
    });
  }

  Future<void> _saveServers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'servers_v1', json.encode(_servers.map((e) => e.toJson()).toList()));
    if (_selectedKey != null) {
      await prefs.setString('last_server_key_v1', _selectedKey!);
    }
  }

  Future<void> _selectServer(String key) async {
    final entry = _servers.firstWhere((e) => e.key == key);
    await _ensureContextFor(entry);
    setState(() {
      _selectedKey = key;
    });
    await _saveServers();
  }

  Future<void> _addServer() async {
    final name = _serverNameController.text.trim();
    final urlText = _serverUrlController.text.trim();
    if (name.isEmpty || urlText.isEmpty) return;
    Uri? uri;
    try {
      uri = Uri.parse(urlText);
      if (!uri.hasScheme) uri = Uri.parse('https://$urlText');
    } catch (_) {
      return;
    }
    final entry = ServerEntry(name: name, url: uri.toString());
    // 既存サーバー（同一キー）があれば重複追加せず選択・必要なら名称更新
    final key = entry.key;
    final existingIndex = _servers.indexWhere((e) => e.key == key);
    if (existingIndex != -1) {
      final existing = _servers[existingIndex];
      if (existing.name != name) {
        final updated = ServerEntry(name: name, url: existing.url);
        setState(() {
          final next = [..._servers];
          next[existingIndex] = updated;
          _servers = next;
          _selectedKey = updated.key;
          _serverNameController.clear();
        });
      } else {
        setState(() {
          _selectedKey = existing.key;
          _serverNameController.clear();
        });
      }
      await _saveServers();
      return;
    }
    await _ensureContextFor(entry);
    setState(() {
      _servers = [..._servers, entry];
      _selectedKey = entry.key;
      _serverNameController.clear();
    });
    await _saveServers();
  }

  Future<void> _removeSelectedServer() async {
    final key = _selectedKey;
    if (key == null) return;
    final remain = _servers.where((e) => e.key != key).toList();
    final ctx = _contexts.remove(key);
    if (ctx != null) {
      await ctx.close();
    }
    String? nextKey;
    if (remain.isNotEmpty) nextKey = remain.first.key;
    setState(() {
      _servers = remain;
      _selectedKey = nextKey;
    });
    await _saveServers();
  }

  Future<void> _ensureContextFor(ServerEntry entry) async {
    final key = entry.key;
    if (_contexts.containsKey(key)) return;
    final dir = await getApplicationDocumentsDirectory();
    final isar =
        await openEmojiIsarForServer(Uri.parse(entry.url), directory: dir.path);
    final http = MisskeyHttpClient(
        config: MisskeyApiConfig(baseUrl: Uri.parse(entry.url)));
    final api = MisskeyEmojiApi(http);
    final store = IsarEmojiStore(isar);
    final catalog = PersistentEmojiCatalog(
      api: api,
      store: store,
      meta: MetaClient(http),
      ttl: const Duration(minutes: 30),
    );
    final resolver = MisskeyEmojiResolver(catalog);
    _contexts[key] = ServerContext(
      isar: isar,
      http: http,
      api: api,
      store: store,
      catalog: catalog,
      resolver: resolver,
    );
  }

  ServerContext? _currentContext() {
    final key = _selectedKey;
    if (key == null) return null;
    return _contexts[key];
  }

  // 旧単一サーバー用の再生成は廃止（サーバー切替は onSelectServer で実施）

  @override
  Widget build(BuildContext context) {
    final ctx = _currentContext();
    final tabs = [
      _SettingsTab(
        servers: _servers,
        selectedKey: _selectedKey,
        onSelectServer: _selectServer,
        serverNameController: _serverNameController,
        serverUrlController: _serverUrlController,
        onAddServer: _addServer,
        onRemoveSelected: _removeSelectedServer,
        onTestConnection: _onTestConnection,
        onSync: _onSync,
        onClearCache: _onClearCache,
        statusText: _status,
        lastSync: _lastSync,
      ),
      _SearchAndGridTab(
        catalog: ctx?.catalog,
        resolver: ctx?.resolver,
      ),
    ];

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Misskey Emoji Example')),
      body: tabs[_tabIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surfaceTint,
        indicatorColor: theme.colorScheme.primaryContainer,
        selectedIndex: _tabIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: '設定'),
          NavigationDestination(
              icon: Icon(Icons.emoji_emotions_outlined),
              selectedIcon: Icon(Icons.emoji_emotions),
              label: '絵文字'),
        ],
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
      ),
    );
  }

  Future<void> _onTestConnection() async {
    final http = _currentContext()?.http;
    if (http == null) return;
    setState(() => _status = '接続テスト中...');
    try {
      // /api/meta を軽く叩く
      await MetaClient(http).getMeta(refresh: true);
      setState(() => _status = '接続OK');
    } catch (e) {
      setState(() => _status = '接続失敗: $e');
    }
  }

  Future<void> _onSync() async {
    final catalog = _currentContext()?.catalog;
    if (catalog == null) return;
    setState(() => _status = '同期中...');
    try {
      await catalog.sync(force: true);
      setState(() {
        _status = '同期完了';
        _lastSync = DateTime.now();
      });
    } catch (e) {
      setState(() => _status = '同期失敗: $e');
    }
  }

  Future<void> _onClearCache() async {
    final isar = _currentContext()?.isar;
    if (isar == null) return;
    await isar.writeTxn(() async {
      await isar.emojiRecordEntitys.clear();
    });
    setState(() => _status = 'キャッシュをクリアしました');
  }
}

class _SettingsTab extends StatelessWidget {
  final List<ServerEntry> servers;
  final String? selectedKey;
  final Future<void> Function(String key) onSelectServer;
  final TextEditingController serverNameController;
  final TextEditingController serverUrlController;
  final Future<void> Function() onAddServer;
  final Future<void> Function() onRemoveSelected;
  final Future<void> Function() onTestConnection;
  final Future<void> Function() onSync;
  final Future<void> Function() onClearCache;
  final String statusText;
  final DateTime? lastSync;

  const _SettingsTab({
    required this.servers,
    required this.selectedKey,
    required this.onSelectServer,
    required this.serverNameController,
    required this.serverUrlController,
    required this.onAddServer,
    required this.onRemoveSelected,
    required this.onTestConnection,
    required this.onSync,
    required this.onClearCache,
    required this.statusText,
    required this.lastSync,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dropdownValue =
        servers.any((s) => s.key == selectedKey) ? selectedKey : null;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('サーバー', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: dropdownValue,
                items: servers
                    .map((s) => DropdownMenuItem(
                          value: s.key,
                          child: Text('${s.name}  (${Uri.parse(s.url).host})'),
                        ))
                    .toList(),
                onChanged: (v) => v != null ? onSelectServer(v) : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemoveSelected,
              icon: const Icon(Icons.delete_outline),
              tooltip: '選択サーバーを削除',
            ),
          ]),
          const SizedBox(height: 16),
          Text('サーバーを追加', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final confirmed = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) {
                    final viewInsets = MediaQuery.of(ctx).viewInsets;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: viewInsets.bottom,
                      ),
                      child: _AddServerSheet(
                        nameController: serverNameController,
                        urlController: serverUrlController,
                        onSubmit: onAddServer,
                      ),
                    );
                  },
                );
                if (confirmed == true) {
                  // 追加済み
                }
              },
              label: const Text('サーバーを追加'),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonal(
                onPressed: onTestConnection, child: const Text('接続テスト')),
            FilledButton(onPressed: onSync, child: const Text('今すぐ同期')),
            OutlinedButton(
                onPressed: onClearCache, child: const Text('キャッシュをクリア')),
          ]),
          const SizedBox(height: 16),
          Text('状態: $statusText'),
          if (lastSync != null) Text('最終同期: $lastSync'),
        ],
      ),
    );
  }
}

class _AddServerSheet extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController urlController;
  final Future<void> Function() onSubmit;

  const _AddServerSheet({
    required this.nameController,
    required this.urlController,
    required this.onSubmit,
  });

  @override
  State<_AddServerSheet> createState() => _AddServerSheetState();
}

class _AddServerSheetState extends State<_AddServerSheet> {
  bool _submitting = false;

  bool get _canSubmit {
    return widget.nameController.text.trim().isNotEmpty &&
        widget.urlController.text.trim().isNotEmpty &&
        !_submitting;
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit();
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(() => setState(() {}));
    widget.urlController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.nameController.removeListener(() {});
    widget.urlController.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_link),
                const SizedBox(width: 8),
                const Text('サーバーを追加',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '表示名',
                hintText: '例: misskey.io',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.urlController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleSubmit(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'URL',
                hintText: 'https://example.com',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _canSubmit ? _handleSubmit : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('追加'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class ServerEntry {
  final String name;
  final String url;
  const ServerEntry({required this.name, required this.url});

  String get key => serverKeyFromBaseUrl(Uri.parse(url));

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
      };
  factory ServerEntry.fromJson(Map<String, dynamic> json) =>
      ServerEntry(name: json['name'] as String, url: json['url'] as String);
}

class ServerContext {
  final Isar isar;
  final MisskeyHttpClient http;
  final MisskeyEmojiApi api;
  final IsarEmojiStore store;
  final PersistentEmojiCatalog catalog;
  final MisskeyEmojiResolver resolver;

  const ServerContext({
    required this.isar,
    required this.http,
    required this.api,
    required this.store,
    required this.catalog,
    required this.resolver,
  });

  Future<void> close() async {
    try {
      await isar.close();
    } catch (_) {}
  }
}

class _SearchAndGridTab extends StatefulWidget {
  final PersistentEmojiCatalog? catalog;
  final MisskeyEmojiResolver? resolver;
  const _SearchAndGridTab({required this.catalog, required this.resolver});

  @override
  State<_SearchAndGridTab> createState() => _SearchAndGridTabState();
}

class _SearchAndGridTabState extends State<_SearchAndGridTab> {
  late final TextEditingController _searchController;
  String? _selectedCategory;
  final Set<String> _revealedSensitive = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    final resolver = widget.resolver;
    final canUse = catalog != null && resolver != null;

    final items = canUse
        ? (() {
            final text = _searchController.text.trim();
            if (text.isEmpty) {
              // 空検索時は全件（カテゴリで絞り込み）を表示
              // snapshotは name と alias をキーに同一レコードを複数回含むため、
              // 主名キー（key == value.name）のみを採用して重複を除去する。
              final list = catalog
                  .snapshot()
                  .entries
                  .where((kv) => kv.key == kv.value.name)
                  .map((kv) => kv.value)
                  .where((e) =>
                      _selectedCategory == null ||
                      e.category == _selectedCategory)
                  .toList();
              list.sort((a, b) => a.name.compareTo(b.name));
              return list;
            }
            return EmojiSearch(catalog)
                .query(text, category: _selectedCategory, limit: 1000000);
          })()
        : const <EmojiRecord>[];

    // 検索語に応じたカテゴリ件数
    final filteredByText = canUse
        ? (() {
            final text = _searchController.text.trim();
            if (text.isEmpty) {
              final list = catalog
                  .snapshot()
                  .entries
                  .where((kv) => kv.key == kv.value.name)
                  .map((kv) => kv.value)
                  .toList();
              list.sort((a, b) => a.name.compareTo(b.name));
              return list;
            }
            return EmojiSearch(catalog).query(text, limit: 1000000);
          })()
        : const <EmojiRecord>[];

    final Map<String, int> categoryCounts = <String, int>{};
    for (final e in filteredByText) {
      final c = e.category;
      if (c != null && c.isNotEmpty) {
        categoryCounts[c] = (categoryCounts[c] ?? 0) + 1;
      }
    }
    final sortedCategories = categoryCounts.keys.toList()..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '絵文字名で検索（前方一致）',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            children: [
              ChoiceChip(
                label: Text('ALL (${filteredByText.length})'),
                selected: _selectedCategory == null,
                onSelected: (_) => setState(() => _selectedCategory = null),
              ),
              const SizedBox(width: 8),
              ...sortedCategories.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$c (${categoryCounts[c]})'),
                      selected: _selectedCategory == c,
                      onSelected: (_) => setState(() => _selectedCategory = c),
                    ),
                  )),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: canUse
              ? RefreshIndicator(
                  onRefresh: () async {
                    await widget.catalog!.sync(force: true);
                    if (mounted) setState(() {});
                  },
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 200),
                            Center(child: Text('該当する絵文字がありません')),
                            SizedBox(height: 200),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 96,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final e = items[index];
                            final bool sensitiveHidden = e.isSensitive &&
                                !_revealedSensitive.contains(e.name);
                            return InkWell(
                              onTap: () async {
                                final img = await resolver.resolve(e.name);
                                if (!context.mounted) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        _EmojiDetailPage(record: e, image: img),
                                  ),
                                );
                              },
                              onLongPress: () {
                                if (!e.isSensitive) return;
                                setState(() {
                                  if (_revealedSensitive.contains(e.name)) {
                                    _revealedSensitive.remove(e.name);
                                  } else {
                                    _revealedSensitive.add(e.name);
                                  }
                                });
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Hero(
                                      tag: e.name,
                                      child: Builder(
                                        builder: (_) {
                                          Widget img = CachedNetworkImage(
                                            imageUrl: e.url,
                                            fit: BoxFit.contain,
                                            memCacheWidth: 64,
                                            memCacheHeight: 64,
                                            placeholder: (_, __) => const Center(
                                                child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2))),
                                            errorWidget: (_, __, ___) =>
                                                const Icon(
                                                    Icons.broken_image_outlined,
                                                    size: 20),
                                            fadeInDuration: const Duration(
                                                milliseconds: 150),
                                            fadeOutDuration: const Duration(
                                                milliseconds: 100),
                                          );
                                          if (sensitiveHidden) {
                                            img = ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  ImageFiltered(
                                                    imageFilter:
                                                        ImageFilter.blur(
                                                            sigmaX: 6,
                                                            sigmaY: 6),
                                                    child: img,
                                                  ),
                                                  const Center(
                                                    child: Icon(
                                                      Icons
                                                          .visibility_off_outlined,
                                                      size: 18,
                                                      color: Colors.white70,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            );
                                          }
                                          return img;
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    e.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                )
              : const Center(child: Text('設定タブで初期化してください')),
        )
      ],
    );
  }
}

class _EmojiDetailPage extends StatelessWidget {
  final EmojiRecord record;
  final EmojiImage? image;
  const _EmojiDetailPage({required this.record, required this.image});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(':${record.name}:')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Hero(
              tag: record.name,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: record.url,
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                  ),
                  fadeInDuration: const Duration(milliseconds: 150),
                  fadeOutDuration: const Duration(milliseconds: 100),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _Chip(theme, 'category', record.category ?? '-'),
            _Chip(theme, 'animated', image?.animated == true ? 'yes' : 'no'),
            _Chip(theme, 'sensitive', record.isSensitive ? 'yes' : 'no'),
            _Chip(theme, 'localOnly', record.localOnly ? 'yes' : 'no'),
          ]),
          const SizedBox(height: 16),
          SelectableText('url: ${record.url}'),
          const SizedBox(height: 8),
          SelectableText('aliases: ${record.aliases.join(', ')}'),
          const SizedBox(height: 8),
          SelectableText('allowRoleIds: ${record.allowRoleIds.join(', ')}'),
          const SizedBox(height: 8),
          SelectableText('denyRoleIds: ${record.denyRoleIds.join(', ')}'),
        ],
      ),
    );
  }

  Widget _Chip(ThemeData theme, String key, String value) {
    return Chip(
      label: Text('$key: $value'),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    );
  }
}
