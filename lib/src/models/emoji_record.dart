/// キャッシュに保存され、解決に用いられる不変の絵文字レコード
class EmojiRecord {
  const EmojiRecord({
    required this.name,
    required this.aliases,
    required this.url,
    this.category,
    required this.localOnly,
    required this.isSensitive,
    required this.allowRoleIds,
  });

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

  /// アニメーション画像かどうかの簡易推定
  bool get animated {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    return path.endsWith('.gif') ||
        path.endsWith('.apng') ||
        path.endsWith('.webp');
  }
}
