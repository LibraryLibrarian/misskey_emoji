import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

class EmojiDetailPage extends StatelessWidget {
  final EmojiRecord record;
  final EmojiImage? image;
  const EmojiDetailPage({super.key, required this.record, required this.image});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(':${record.name}:')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Hero(
              tag: record.name,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: record.url,
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                  ),
                  fadeInDuration: const Duration(milliseconds: 150),
                  fadeOutDuration: const Duration(milliseconds: 100),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _buildChip(theme, 'category', record.category ?? '未分類'),
            _buildChip(
                theme, 'animated', image?.animated == true ? 'yes' : 'no'),
            _buildChip(theme, 'sensitive', record.isSensitive ? 'yes' : 'no'),
            _buildChip(theme, 'localOnly', record.localOnly ? 'yes' : 'no'),
          ]),
          const SizedBox(height: 16),
          _buildCardSection(
            context,
            title: '基本情報',
            children: [
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('URL'),
                subtitle: SelectableText(record.url),
              ),
              if (record.aliases.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: const Text('エイリアス'),
                  subtitle: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: record.aliases
                        .map((a) => Chip(
                              label: Text(a),
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCardSection(
            context,
            title: 'ロール制限',
            children: [
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('allowRoleIds'),
                subtitle: record.allowRoleIds.isEmpty
                    ? const Text('なし')
                    : _buildIdWrap(record.allowRoleIds),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdWrap(List<String> ids) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ids
          .map((id) => Chip(
                label: Text(id),
                visualDensity: VisualDensity.compact,
              ))
          .toList(),
    );
  }

  Widget _buildCardSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildChip(ThemeData theme, String key, String value) {
    return Chip(
      label: Text('$key: $value'),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    );
  }
}
