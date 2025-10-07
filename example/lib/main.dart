import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
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

  @override
  Widget build(BuildContext context) {
    final ctx = _currentContext();
    final selectedServer = _servers.firstWhere(
      (s) => s.key == _selectedKey,
      orElse: () => _servers.isNotEmpty
          ? _servers.first
          : ServerEntry(name: '未選択', url: ''),
    );

    return Scaffold(
      appBar: AppBar(
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            onPressed: _onSync,
            tooltip: '同期',
          ),
        ],
      ),
      drawer: _SettingsDrawer(
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
      body: _EmojiGrid(
        catalog: ctx?.catalog,
        resolver: ctx?.resolver,
        onSync: _onSync,
      ),
    );
  }
}

/// 設定画面をDrawerとして表示するウィジェット
class _SettingsDrawer extends StatelessWidget {
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

  const _SettingsDrawer({
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
    return Drawer(
      child: Stack(
        children: [
          // 背景は画面全体に表示
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          // コンテンツ部分のみSafeAreaでラップ
          SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildServerSection(context),
                const Divider(),
                _buildActionsSection(context),
                const Divider(),
                _buildStatusSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dropdownValue =
        servers.any((s) => s.key == selectedKey) ? selectedKey : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dns, size: 20),
              const SizedBox(width: 8),
              Text('サーバー設定', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: dropdownValue,
            items: servers
                .map((s) => DropdownMenuItem(
                      value: s.key,
                      child: Text('${s.name} (${Uri.parse(s.url).host})'),
                    ))
                .toList(),
            onChanged: (v) => v != null ? onSelectServer(v) : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '選択中のサーバー',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddServerDialog(context),
                  label: const Text('サーバーを追加'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemoveSelected,
                label: const Text('削除'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 20),
              const SizedBox(width: 8),
              Text('操作', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: onTestConnection,
                child: const Text('接続テスト'),
              ),
              FilledButton(
                onPressed: onSync,
                child: const Text('今すぐ同期'),
              ),
              OutlinedButton(
                onPressed: onClearCache,
                child: const Text('キャッシュクリア'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 20),
              const SizedBox(width: 8),
              Text('状態', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('状態: $statusText', style: textTheme.bodyMedium),
                if (lastSync != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '最終同期: ${lastSync.toString().substring(0, 19)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddServerDialog(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: _AddServerSheet(
            nameController: serverNameController,
            urlController: serverUrlController,
            onSubmit: onAddServer,
          ),
        );
      },
    );
  }
}

/// 絵文字グリッドを表示するウィジェット
class _EmojiGrid extends StatefulWidget {
  final PersistentEmojiCatalog? catalog;
  final MisskeyEmojiResolver? resolver;
  final Future<void> Function() onSync;

  const _EmojiGrid({
    required this.catalog,
    required this.resolver,
    required this.onSync,
  });

  @override
  State<_EmojiGrid> createState() => _EmojiGridState();
}

class _EmojiGridState extends State<_EmojiGrid> {
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

    if (!canUse) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_emotions_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '設定からサーバーを選択してください',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.settings),
              onPressed: () => Scaffold.of(context).openDrawer(),
              label: const Text('設定を開く'),
            ),
          ],
        ),
      );
    }

    final items = _getFilteredItems(catalog);
    final categoryCounts = _getCategoryCounts(catalog);
    final sortedCategories = categoryCounts.keys.toList()..sort();

    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoryFilter(sortedCategories, categoryCounts),
        const Divider(height: 1),
        Expanded(
          child: _buildEmojiGrid(items, resolver),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: '絵文字名で検索（前方一致）',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildCategoryFilter(
      List<String> categories, Map<String, int> counts) {
    final allCount = counts.values.fold(0, (sum, count) => sum + count);

    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: Text('ALL ($allCount)'),
            selected: _selectedCategory == null,
            onSelected: (_) => setState(() => _selectedCategory = null),
          ),
          const SizedBox(width: 8),
          ...categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$c (${counts[c]})'),
                  selected: _selectedCategory == c,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmojiGrid(
      List<EmojiRecord> items, MisskeyEmojiResolver resolver) {
    return RefreshIndicator(
      onRefresh: () async {
        await widget.onSync();
        if (mounted) setState(() {});
      },
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 200),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        _searchController.text.trim().isEmpty
                            ? Icons.sync_problem
                            : Icons.search_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.trim().isEmpty
                            ? '絵文字を同期してください'
                            : '該当する絵文字がありません',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      if (_searchController.text.trim().isEmpty) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(Icons.sync),
                          onPressed: () async {
                            await widget.onSync();
                            if (mounted) setState(() {});
                          },
                          label: const Text('今すぐ同期'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 200),
              ],
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 96,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final e = items[index];
                final bool sensitiveHidden =
                    e.isSensitive && !_revealedSensitive.contains(e.name);
                return _buildEmojiItem(e, sensitiveHidden, resolver);
              },
            ),
    );
  }

  Widget _buildEmojiItem(
      EmojiRecord e, bool sensitiveHidden, MisskeyEmojiResolver resolver) {
    return InkWell(
      onTap: () async {
        final img = await resolver.resolve(e.name);
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _EmojiDetailPage(record: e, image: img),
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
                            child: CircularProgressIndicator(strokeWidth: 2))),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined, size: 20),
                    fadeInDuration: const Duration(milliseconds: 150),
                    fadeOutDuration: const Duration(milliseconds: 100),
                  );
                  if (sensitiveHidden) {
                    img = ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: img,
                          ),
                          const Center(
                            child: Icon(
                              Icons.visibility_off_outlined,
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
  }

  List<EmojiRecord> _getFilteredItems(PersistentEmojiCatalog catalog) {
    final text = _searchController.text.trim();
    if (text.isEmpty) {
      final list = catalog
          .snapshot()
          .entries
          .where((kv) => kv.key == kv.value.name)
          .map((kv) => kv.value)
          .where((e) =>
              _selectedCategory == null || e.category == _selectedCategory)
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    }
    return EmojiSearch(catalog)
        .query(text, category: _selectedCategory, limit: 1000000);
  }

  Map<String, int> _getCategoryCounts(PersistentEmojiCatalog catalog) {
    final text = _searchController.text.trim();
    final filteredByText = text.isEmpty
        ? catalog
            .snapshot()
            .entries
            .where((kv) => kv.key == kv.value.name)
            .map((kv) => kv.value)
            .toList()
        : EmojiSearch(catalog).query(text, limit: 1000000);

    final Map<String, int> categoryCounts = <String, int>{};
    for (final e in filteredByText) {
      final c = e.category;
      if (c != null && c.isNotEmpty) {
        categoryCounts[c] = (categoryCounts[c] ?? 0) + 1;
      }
    }
    return categoryCounts;
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
            _buildChip(theme, 'category', record.category ?? '-'),
            _buildChip(
                theme, 'animated', image?.animated == true ? 'yes' : 'no'),
            _buildChip(theme, 'sensitive', record.isSensitive ? 'yes' : 'no'),
            _buildChip(theme, 'localOnly', record.localOnly ? 'yes' : 'no'),
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

  Widget _buildChip(ThemeData theme, String key, String value) {
    return Chip(
      label: Text('$key: $value'),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    );
  }
}
