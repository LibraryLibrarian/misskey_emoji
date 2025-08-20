class EmojiRecord {
  final String name;
  final List<String> aliases;
  final String url;
  final String? category;
  final bool localOnly;
  final bool isSensitive;
  final List<String> allowRoleIds;
  final List<String> denyRoleIds;

  const EmojiRecord({
    required this.name,
    required this.aliases,
    required this.url,
    this.category,
    required this.localOnly,
    required this.isSensitive,
    required this.allowRoleIds,
    required this.denyRoleIds,
  });

  bool get animated {
    final u = url.toLowerCase();
    return u.endsWith('.gif') || u.endsWith('.apng') || u.endsWith('.webp');
  }
}


