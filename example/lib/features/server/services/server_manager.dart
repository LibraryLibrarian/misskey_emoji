import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:misskey_api_core/misskey_api_core.dart';
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_context.dart';
import '../models/server_entry.dart';

class ServerManager extends ChangeNotifier {
  static const _serversKey = 'servers_v1';
  static const _lastServerKey = 'last_server_key_v1';

  final Map<String, ServerContext> _contexts = {};
  List<ServerEntry> _servers = [];
  String? _selectedKey;
  String _status = '未初期化';
  DateTime? _lastSync;
  bool _isSyncing = false;
  bool _initialized = false;

  List<ServerEntry> get servers => List.unmodifiable(_servers);
  String? get selectedKey => _selectedKey;
  String get status => _status;
  DateTime? get lastSync => _lastSync;
  bool get isSyncing => _isSyncing;

  ServerEntry? get selectedServer => _servers
      .cast<ServerEntry?>()
      .firstWhere((s) => s?.key == _selectedKey, orElse: () => null);

  ServerContext? get currentContext {
    final key = _selectedKey;
    if (key == null) return null;
    return _contexts[key];
  }

  Future<void> init() async {
    if (_initialized) return;
    _status = '初期化中...';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final loaded = prefs.getString(_serversKey);
    final last = prefs.getString(_lastServerKey);
    List<ServerEntry> servers = [];
    if (loaded != null && loaded.isNotEmpty) {
      final list =
          (json.decode(loaded) as List?)?.cast<Map<String, dynamic>>() ??
              const [];
      servers = list.map((j) => ServerEntry.fromJson(j)).toList();
      if (servers.isNotEmpty) {
        final seen = <String>{};
        servers = servers.where((e) => seen.add(e.key)).toList();
      }
    }
    if (servers.isEmpty) {
      servers = [ServerEntry(name: 'misskey.io', url: 'https://misskey.io')];
      await prefs.setString(
          _serversKey, json.encode(servers.map((e) => e.toJson()).toList()));
    }
    String selectedKey = last ?? servers.first.key;
    final selectedEntry = servers.firstWhere((e) => e.key == selectedKey,
        orElse: () => servers.first);
    await _ensureContextFor(selectedEntry);
    _servers = servers;
    _selectedKey = selectedEntry.key;
    _status = '準備完了';
    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveServers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _serversKey, json.encode(_servers.map((e) => e.toJson()).toList()));
    if (_selectedKey != null) {
      await prefs.setString(_lastServerKey, _selectedKey!);
    }
  }

  Future<void> selectServer(String key) async {
    final entry = _servers.firstWhere((e) => e.key == key);
    await _ensureContextFor(entry);
    _selectedKey = key;
    notifyListeners();
    await _saveServers();
  }

  Future<bool> addServer(String name, String urlText) async {
    if (name.trim().isEmpty || urlText.trim().isEmpty) return false;
    Uri? uri;
    try {
      uri = Uri.parse(urlText.trim());
      if (!uri.hasScheme) uri = Uri.parse('https://$urlText');
    } catch (_) {
      _status = 'URLが無効です';
      notifyListeners();
      return false;
    }
    final entry = ServerEntry(name: name.trim(), url: uri.toString());
    final key = entry.key;
    final existingIndex = _servers.indexWhere((e) => e.key == key);
    if (existingIndex != -1) {
      final existing = _servers[existingIndex];
      if (existing.name != entry.name) {
        final updated = ServerEntry(name: entry.name, url: existing.url);
        _servers = [..._servers]..[existingIndex] = updated;
        _selectedKey = updated.key;
      } else {
        _selectedKey = existing.key;
      }
      notifyListeners();
      await _saveServers();
      return true;
    }
    await _ensureContextFor(entry);
    _servers = [..._servers, entry];
    _selectedKey = entry.key;
    notifyListeners();
    await _saveServers();
    return true;
  }

  Future<void> removeSelectedServer() async {
    final key = _selectedKey;
    if (key == null) return;
    final remain = _servers.where((e) => e.key != key).toList();
    final ctx = _contexts.remove(key);
    if (ctx != null) {
      await ctx.close();
    }
    _servers = remain;
    _selectedKey = remain.isNotEmpty ? remain.first.key : null;
    notifyListeners();
    await _saveServers();
  }

  Future<void> testConnection() async {
    final http = currentContext?.http;
    if (http == null) return;
    _status = '接続テスト中...';
    notifyListeners();
    try {
      await MetaClient(http).getMeta(refresh: true);
      _status = '接続OK';
    } catch (e) {
      _status = '接続失敗: $e';
    }
    notifyListeners();
  }

  Future<void> sync() async {
    final catalog = currentContext?.catalog;
    if (catalog == null) return;
    _status = '同期中...';
    _isSyncing = true;
    notifyListeners();
    try {
      await catalog.sync(force: true);
      _status = '同期完了';
      _lastSync = DateTime.now();
    } catch (e) {
      _status = '同期失敗: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> clearCache() async {
    final isar = currentContext?.isar;
    if (isar == null) return;
    await isar.writeTxn(() async {
      await isar.emojiRecordEntitys.clear();
    });
    _status = 'キャッシュをクリアしました';
    notifyListeners();
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

  Future<void> close() async {
    for (final c in _contexts.values) {
      await c.close();
    }
    _contexts.clear();
  }
}
