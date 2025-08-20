import 'dart:async';

import 'package:misskey_api_core/misskey_api_core.dart';

import '../api/misskey_emoji_api.dart';
import '../models/emoji_dto.dart';
import '../models/emoji_record.dart';
import 'catalog.dart';

class InMemoryEmojiCatalog implements EmojiCatalog {
  final MisskeyEmojiApi api;
  final MetaClient? meta;
  final Duration ttl;

  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void>? _ongoing;
  Map<String, EmojiRecord> _byKey = {};

  InMemoryEmojiCatalog({
    required this.api,
    this.meta,
    this.ttl = const Duration(minutes: 30),
  });

  @override
  EmojiRecord? get(String code) => _byKey[_norm(code)];

  @override
  Map<String, EmojiRecord> snapshot() => Map.unmodifiable(_byKey);

  @override
  Future<void> sync({bool force = false}) async {
    if (!force && DateTime.now().difference(_last) < ttl) return;
    _ongoing ??= _doSync();
    try {
      await _ongoing;
    } finally {
      _ongoing = null;
    }
  }

  Future<void> _doSync() async {
    if (_byKey.isEmpty && meta != null) {
      final m = await meta!.getMeta();
      final metaEmojis = (m.raw['emojis'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      if (metaEmojis.isNotEmpty) {
        final list = metaEmojis.map((j) => api.toRecord(EmojiDto.fromJson(j))).toList();
        _byKey = _index(list);
      }
    }
    final newest = await api.fetchAll();
    _byKey = _index(newest);
    _last = DateTime.now();
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

  String _norm(String s) {
    final t = s.trim();
    final core = (t.startsWith(':') && t.endsWith(':') && t.length >= 2)
        ? t.substring(1, t.length - 1)
        : t;
    return core.toLowerCase();
  }
}


