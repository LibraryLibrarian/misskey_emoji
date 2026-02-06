/// ファイルサイズをバイト数から人間が読みやすい形式に変換する
///
/// 例:
/// - 1024 → "1.0 KB"
/// - 1048576 → "1.0 MB"
/// - 0 → "0 B"
String formatFileSize(int bytes) {
  if (bytes <= 0) return '0 B';
  
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (bytes.bitLength - 1) ~/ 10;
  final index = i.clamp(0, suffixes.length - 1);
  final size = bytes / (1 << (index * 10));
  
  return '${size.toStringAsFixed(index == 0 ? 0 : 1)} ${suffixes[index]}';
}
