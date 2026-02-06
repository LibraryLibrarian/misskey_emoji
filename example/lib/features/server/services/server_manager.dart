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
  final Map<String, int> _catalogVersions = {};
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

  int catalogVersionFor(String? key) {
    if (key == null) return 0;
    return _catalogVersions[key] ?? 0;
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
    _servers = servers;
    if (servers.isNotEmpty) {
      String selectedKey = last ?? servers.first.key;
      final selectedEntry = servers.firstWhere((e) => e.key == selectedKey,
          orElse: () => servers.first);
      await _ensureContextFor(selectedEntry);
      _selectedKey = selectedEntry.key;
    } else {
      _selectedKey = null;
    }
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

  /// 指定キーのサーバーを削除する
  Future<void> removeServer(String key) async {
    final remain = _servers.where((e) => e.key != key).toList();
    final ctx = _contexts.remove(key);
    _catalogVersions.remove(key);
    if (ctx != null) {
      await ctx.close();
    }
    _servers = remain;
    if (_selectedKey == key) {
      _selectedKey = remain.isNotEmpty ? remain.first.key : null;
    }
    notifyListeners();
    await _saveServers();
  }

  /// 指定キーのサーバーに対して接続テストを行う
  Future<bool> testConnectionFor(String key) async {
    final ctx = _contexts[key];
    if (ctx == null) return false;
    _status = '接続テスト中...';
    notifyListeners();
    try {
      await MetaClient(ctx.http).getMeta(refresh: true);
      _status = '接続OK';
      notifyListeners();
      return true;
    } catch (e) {
      _status = '接続失敗: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> sync() async {
    final catalog = currentContext?.catalog;
    if (catalog == null) return;
    _status = '同期中...';
    _isSyncing = true;
    notifyListeners();
    try {
      await catalog.sync(force: true);
      final key = _selectedKey;
      if (key != null) {
        _catalogVersions[key] = (_catalogVersions[key] ?? 0) + 1;
      }
      _status = '同期完了';
      _lastSync = DateTime.now();
    } catch (e) {
      _status = '同期失敗: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 指定キーのサーバーのキャッシュをクリア
  Future<void> clearCacheFor(String key) async {
    final ctx = _contexts[key];
    if (ctx == null) return;
    await ctx.isar.writeTxn(() async {
      await ctx.isar.emojiRecordEntitys.clear();
    });
    _status = 'キャッシュをクリアしました';
    notifyListeners();
  }

  /// 指定キーのサーバーの絵文字数を取得
  Future<int> getEmojiCountFor(String key) async {
    final ctx = _contexts[key];
    if (ctx == null) {
      // コンテキストが未初期化の場合、対応するサーバーを初期化
      final entry = _servers.cast<ServerEntry?>().firstWhere(
            (e) => e?.key == key,
            orElse: () => null,
          );
      if (entry == null) return 0;
      await _ensureContextFor(entry);
      final newCtx = _contexts[key];
      if (newCtx == null) return 0;
      return newCtx.isar.emojiRecordEntitys.count();
    }
    return ctx.isar.emojiRecordEntitys.count();
  }

  /// 指定キーのサーバーのデータベース使用サイズを取得（バイト数）
  ///
  /// Isarの`getSize()`メソッドを使用して、実際に使用されているデータサイズを取得
  /// 取得失敗時は-1を返す
  Future<int> getDatabaseSizeFor(String key) async {
    try {
      final ctx = _contexts[key];
      if (ctx == null) {
        // コンテキストが未初期化の場合、対応するサーバーを初期化
        final entry = _servers.cast<ServerEntry?>().firstWhere(
              (e) => e?.key == key,
              orElse: () => null,
            );
        if (entry == null) return -1;

        await _ensureContextFor(entry);
        final newCtx = _contexts[key];
        if (newCtx == null) return -1;

        return await newCtx.isar.emojiRecordEntitys.getSize();
      }

      return await ctx.isar.emojiRecordEntitys.getSize();
    } catch (e) {
      return -1;
    }
  }

  /// 指定URLのサーバーが既に追加済みか判定する
  bool isServerAdded(String url) {
    try {
      final uri = Uri.parse(url);
      final key = serverKeyFromBaseUrl(uri);
      return _servers.any((e) => e.key == key);
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureContextFor(ServerEntry entry) async {
    final key = entry.key;
    if (_contexts.containsKey(key)) return;
    _catalogVersions.putIfAbsent(key, () => 0);
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
    _catalogVersions.clear();
  }
}
