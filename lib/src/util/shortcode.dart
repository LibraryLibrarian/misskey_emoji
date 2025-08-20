// Misskey絵文字ショートコードのユーティリティ
//
// ライブラリ全体で一貫した正規化を提供し、周囲のコロン、空白、大文字小文字などの入力の変化によってキーが安定するようにする

/// 一貫した比較と検索のためにショートコード文字列を正規化する
///
/// - 周囲の空白を削除する
/// - 周囲の `:` が存在する場合は削除する（":name:")
/// - 結果を小文字に変換する
/// - 誤って含まれている場合は絵文字変化セレクタ U+FE0F を削除する
String normalizeShortcode(String input) {
  final trimmed = input.trim();
  final hasColonWrap = trimmed.length >= 2 && trimmed.startsWith(':') && trimmed.endsWith(':');
  final core = hasColonWrap ? trimmed.substring(1, trimmed.length - 1) : trimmed;
  // 絵文字変化セレクタ (U+FE0F) が存在する場合は削除する
  final withoutVariation = core.replaceAll('\uFE0F', '');
  return withoutVariation.toLowerCase();
}