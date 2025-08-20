import 'dart:async';

import 'package:misskey_api_core/misskey_api_core.dart';

import '../api/misskey_emoji_api.dart';
import '../models/emoji_dto.dart';
import '../models/emoji_record.dart';
import '../cache/emoji_store.dart';
import '../util/shortcode.dart';
import 'catalog.dart';

/// [EmojiStore]を用いた永続化対応の[EmojiCatalog]実装
///
/// - 初回アクセス時に[store]からキャッシュをロード
/// - キャッシュが空ならmetaで事前充填
/// - 同期成功後は最新の絵文字を[store]に保存
/// - TTLとエラー時クールダウンを尊重して無駄な再試行を避ける
class PersistentEmojiCatalog implements EmojiCatalog {
  /// 絵文字取得に用いるAPIクライアント
  final MisskeyEmojiApi api;

  /// インスタンスのメタから事前充填するためのMetaClient（任意）
  final MetaClient? meta;

  /// 絵文字キャッシュを保持する永続ストア
  final EmojiStore store;

  /// 同期のTTL。この時間内は再同期をスキップ
  final Duration ttl;

  /// 同期失敗後に適用するクールダウン時間
  final Duration errorCooldown;

  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _lastError;
  Future<void>? _ongoing;
  Map<String, EmojiRecord> _byKey = {};

  PersistentEmojiCatalog({
    required this.api,
    required this.store,
    this.meta,
    this.ttl = const Duration(minutes: 30),
    this.errorCooldown = const Duration(minutes: 2),
  });

  @override
  EmojiRecord? get(String code) => _byKey[normalizeShortcode(code)];

  /// 現在のインデックスの不変スナップショットを返す
  @override
  Map<String, EmojiRecord> snapshot() => Map.unmodifiable(_byKey);

  /// APIで同期し、その結果を永続化する
  ///
  /// - 初回呼び出しでは[store]からのロードを試みる
  /// - [force]がfalseの場合、[ttl]と[errorCooldown]を尊重する
  @override
  Future<void> sync({bool force = false}) async {
    if (_byKey.isEmpty) {
      final cached = await store.loadAll();
      if (cached.isNotEmpty) {
        _byKey = _index(cached);
      }
    }

    final now = DateTime.now();
    if (!force) {
      if (now.difference(_last) < ttl) return;
      if (_lastError != null && now.difference(_lastError!) < errorCooldown)
        return;
    }
    _ongoing ??= _doSync();
    try {
      await _ongoing;
    } finally {
      _ongoing = null;
    }
  }

  Future<void> _doSync() async {
    try {
      if (_byKey.isEmpty && meta != null) {
        final m = await meta!.getMeta();
        final metaEmojis =
            (m.raw['emojis'] as List?)?.cast<Map<String, dynamic>>() ??
                const [];
        if (metaEmojis.isNotEmpty) {
          final list = metaEmojis
              .map((j) => api.toRecord(EmojiDto.fromJson(j)))
              .toList();
          _byKey = _index(list);
        }
      }
      final newest = await api.fetchAll();
      _byKey = _index(newest);
      await store.saveAll(newest);
      _last = DateTime.now();
      _lastError = null;
    } catch (_) {
      // 既存のキャッシュを保持; エラー時間を記録してクールダウンを適用
      _lastError = DateTime.now();
    }
  }

  Map<String, EmojiRecord> _index(List<EmojiRecord> list) {
    final map = <String, EmojiRecord>{};
    for (final e in list) {
      map[e.name] = e;
      for (final a in e.aliases) {
        map[a] = e;
      }
    }
    return map;
  }
}
