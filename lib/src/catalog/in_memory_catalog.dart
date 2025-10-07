import 'dart:async';

import 'package:misskey_api_core/misskey_api_core.dart';

import '../api/misskey_emoji_api.dart';
import '../models/emoji_dto.dart';
import '../models/emoji_record.dart';
import '../util/shortcode.dart';
import 'catalog.dart';

/// [EmojiCatalog]のメモリ実装
///
/// - キャッシュが空の場合、`meta`から事前充填
/// - APIから最新の絵文字一覧を取得
/// - メモリにTTL付きで保持
/// - 同期エラー時にはクールダウンを適用
class InMemoryEmojiCatalog implements EmojiCatalog {
  /// 絵文字取得に用いるAPIクライアント
  final MisskeyEmojiApi api;

  /// インスタンスのメタから事前充填するためのMetaClient（任意）
  final MetaClient? meta;

  /// 同期のTTL。この時間内は再同期をスキップ
  final Duration ttl;

  /// 同期失敗後に適用するクールダウン時間
  final Duration errorCooldown;

  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _lastError;
  Future<void>? _ongoing;
  Map<String, EmojiRecord> _byKey = {};

  InMemoryEmojiCatalog({
    required this.api,
    this.meta,
    this.ttl = const Duration(minutes: 30),
    this.errorCooldown = const Duration(minutes: 2),
  });

  /// 指定ショートコードのレコードを返す（なければnull）
  @override
  EmojiRecord? get(String code) => _byKey[normalizeShortcode(code)];

  /// メモリ上のインデックスの不変スナップショットを返す
  @override
  Map<String, EmojiRecord> snapshot() => Map.unmodifiable(_byKey);

  /// カタログをAPI経由で同期する
  ///
  /// - [force]がfalseの場合、[ttl]と[errorCooldown]を尊重する
  @override
  Future<void> sync({bool force = false}) async {
    final now = DateTime.now();
    if (!force) {
      if (now.difference(_last) < ttl) return;
      if (_lastError != null && now.difference(_lastError!) < errorCooldown) {
        return;
      }
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
