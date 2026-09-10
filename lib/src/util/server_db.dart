/// サーバーごとに分離されたキャッシュキーを生成するためのユーティリティ
String serverKeyFromBaseUrl(Uri baseUrl) {
  final scheme = baseUrl.scheme.toLowerCase();
  final host = baseUrl.host.toLowerCase();
  final port = baseUrl.hasPort ? baseUrl.port.toString() : '';
  final raw = [scheme, host, port].where((e) => e.isNotEmpty).join('_');
  final safe = raw.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return safe.replaceAll(RegExp(r'_+'), '_');
}
