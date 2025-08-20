/// キャッシュに保存され、解決に用いられる不変の絵文字レコード
class EmojiRecord {
  /// 正規化済みのプライマリショートコード名
  final String name;

  /// 正規化済みのエイリアスショートコード
  final List<String> aliases;

  /// 絵文字画像の絶対URL
  final String url;

  /// 任意のカテゴリ名
  final String? category;

  /// ローカル限定かどうか
  final bool localOnly;

  /// センシティブとマークされているかどうか
  final bool isSensitive;

  /// この絵文字をリアクションとして使用可能なロールID群
  final List<String> allowRoleIds;

  /// この絵文字をリアクションとして使用不可なロールID群
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

  /// アニメーション画像かどうかの簡易推定
  bool get animated {
    final u = url.toLowerCase();
    return u.endsWith('.gif') || u.endsWith('.apng') || u.endsWith('.webp');
  }
}
