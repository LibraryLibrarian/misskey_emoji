import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_context.dart';
import '../models/server_entry.dart';

typedef ServerContextFactory =
    Future<ServerContext> Function(ServerEntry entry);

class ServerManager extends ChangeNotifier {
  ServerManager({ServerContextFactory? contextFactory})
    : _contextFactory = contextFactory ?? _createDefaultContext;

  static const _serversKey = 'servers_v1';
  static const _lastServerKey = 'last_server_key_v1';

  final ServerContextFactory _contextFactory;
  final Map<String, ServerContext> _contexts = {};
  final Map<String, Future<void>> _contextInitializations = {};
  final Map<String, Future<void>> _serverRemovals = {};
  final Map<String, int> _catalogVersions = {};
  List<ServerEntry> _servers = [];
  String? _selectedKey;
  String _status = '未初期化';
  DateTime? _lastSync;
  bool _isSyncing = false;
  bool _initialized = false;
  Future<void>? _closing;

  List<ServerEntry> get servers => List.unmodifiable(_servers);
  String? get selectedKey => _selectedKey;
  String get status => _status;
  DateTime? get lastSync => _lastSync;
  bool get isSyncing => _isSyncing;

  ServerEntry? get selectedServer => _servers.cast<ServerEntry?>().firstWhere(
    (s) => s?.key == _selectedKey,
    orElse: () => null,
  );

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
      final selectedEntry = servers.firstWhere(
        (e) => e.key == selectedKey,
        orElse: () => servers.first,
      );
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
      _serversKey,
      json.encode(_servers.map((e) => e.toJson()).toList()),
    );
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
  Future<void> removeServer(String key) {
    final existingRemoval = _serverRemovals[key];
    if (existingRemoval != null) return existingRemoval;

    late final Future<void> removal;
    removal = _removeServer(key).whenComplete(() {
      if (identical(_serverRemovals[key], removal)) {
        _serverRemovals.remove(key);
      }
    });
    _serverRemovals[key] = removal;
    return removal;
  }

  Future<void> _removeServer(String key) async {
    final initialization = _contextInitializations[key];
    if (initialization != null) await initialization;

    final context = _contexts[key];
    if (context != null) {
      // closeに失敗した場合はコンテキストと設定を残し、次の削除操作で再試行できる。
      await context.close();
      if (identical(_contexts[key], context)) {
        _contexts.remove(key);
      }
    }
    _catalogVersions.remove(key);
    final remain = _servers.where((entry) => entry.key != key).toList();
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
      await ctx.client.meta.getMeta(refresh: true);
      _status = '接続OK';
      notifyListeners();
      return true;
    } catch (e) {
      _status = '接続失敗: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> sync({bool force = false}) async {
    final catalog = currentContext?.catalog;
    if (catalog == null) return;
    _status = '同期中...';
    _isSyncing = true;
    notifyListeners();
    try {
      await catalog.sync(force: force);
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
    await ctx.store.clear();
    // 現在表示中の一覧は維持する。明示的な同期まで表示を変えない既存の挙動に合わせる。
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
      return newCtx.store.count();
    }
    return ctx.store.count();
  }

  /// 指定キーのサーバーのデータベース使用サイズを取得（バイト数）
  ///
  /// ファイルを持たないストアではnullを返す。取得失敗時は-1を返す。
  Future<int?> getDatabaseSizeFor(String key) async {
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

        return await newCtx.store.sizeInBytes();
      }

      return await ctx.store.sizeInBytes();
    } catch (_) {
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
    final closing = _closing;
    if (closing != null) {
      await closing;
      throw StateError('終了済みのサーバー管理は初期化できません');
    }

    final removal = _serverRemovals[key];
    if (removal != null) {
      await removal;
      if (!_servers.any((server) => server.key == key)) {
        throw StateError('削除済みのサーバーは初期化できません');
      }
    }

    if (_contexts.containsKey(key)) return;
    final initialization = _contextInitializations[key];
    if (initialization != null) return initialization;

    late final Future<void> newInitialization;
    newInitialization = _createContextFor(entry).whenComplete(() {
      if (identical(_contextInitializations[key], newInitialization)) {
        _contextInitializations.remove(key);
      }
    });
    _contextInitializations[key] = newInitialization;
    return newInitialization;
  }

  Future<void> _createContextFor(ServerEntry entry) async {
    final context = await _contextFactory(entry);
    final key = entry.key;
    if (_closing != null) {
      await context.close();
      throw StateError('終了中のサーバー管理は初期化できません');
    }
    _catalogVersions.putIfAbsent(key, () => 0);
    _contexts[key] = context;
  }

  static Future<ServerContext> _createDefaultContext(ServerEntry entry) async {
    final dir = await getApplicationDocumentsDirectory();
    final baseUrl = Uri.parse(entry.url);
    final store = await openEmojiStoreForServer(baseUrl, directory: dir.path);
    final client = MisskeyClient(config: MisskeyClientConfig(baseUrl: baseUrl));
    final source = MisskeyClientEmojiSource(client);
    final catalog = PersistentEmojiCatalog(
      source: source,
      store: store,
      ttl: const Duration(minutes: 30),
    );
    final resolver = MisskeyEmojiResolver(catalog);
    return ServerContext(
      client: client,
      source: source,
      store: store,
      catalog: catalog,
      resolver: resolver,
    );
  }

  Future<void> close() {
    final closing = _closing;
    if (closing != null) return closing;

    late final Future<void> newClosing;
    newClosing = _closeAll().whenComplete(() {
      // close後に再利用する設計ではないため、終了状態を保持する。
    });
    _closing = newClosing;
    return newClosing;
  }

  Future<void> _closeAll() async {
    await Future.wait([
      ..._contextInitializations.values,
      ..._serverRemovals.values,
    ]);

    Object? firstError;
    StackTrace? firstStackTrace;
    for (final entry in _contexts.entries.toList()) {
      try {
        await entry.value.close();
        if (identical(_contexts[entry.key], entry.value)) {
          _contexts.remove(entry.key);
          _catalogVersions.remove(entry.key);
        }
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }
    if (firstError != null)
      Error.throwWithStackTrace(firstError, firstStackTrace!);
  }
}
