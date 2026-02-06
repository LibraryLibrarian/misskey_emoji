/// プリセットとして提供するMisskeyサーバーの定義
class PresetServer {
  final String name;
  final String url;
  final String description;

  const PresetServer({
    required this.name,
    required this.url,
    required this.description,
  });
}

/// メジャーなMisskeyサーバー一覧
const kPresetServers = [
  PresetServer(
    name: 'Misskey.io',
    url: 'https://misskey.io',
    description: '最大規模の汎用インスタンス',
  ),
  PresetServer(
    name: 'Misskey.design',
    url: 'https://misskey.design',
    description: 'デザイナー向けインスタンス',
  ),
  PresetServer(
    name: 'nijimiss.moe',
    url: 'https://nijimiss.moe',
    description: '二次元カルチャー特化',
  ),
  PresetServer(
    name: 'submarin.online',
    url: 'https://submarin.online',
    description: 'misskeyフォーク（互換性確認用）',
  ),
  PresetServer(
    name: 'misskey.art',
    url: 'https://misskey.art',
    description: 'アート・創作向け',
  ),
];
