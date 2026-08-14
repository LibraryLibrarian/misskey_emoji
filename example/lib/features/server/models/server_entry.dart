import 'package:misskey_emoji/misskey_emoji.dart';

class ServerEntry {
  final String name;
  final String url;
  const ServerEntry({required this.name, required this.url});

  String get key => serverKeyFromBaseUrl(Uri.parse(url));

  Map<String, dynamic> toJson() => {'name': name, 'url': url};
  factory ServerEntry.fromJson(Map<String, dynamic> json) =>
      ServerEntry(name: json['name'] as String, url: json['url'] as String);
}
