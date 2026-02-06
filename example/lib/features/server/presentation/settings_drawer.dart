import 'package:flutter/material.dart';

import '../models/server_entry.dart';
import 'add_server_sheet.dart';

/// 設定画面をDrawerとして表示するウィジェット
class SettingsDrawer extends StatelessWidget {
  final List<ServerEntry> servers;
  final String? selectedKey;
  final Future<void> Function(String key) onSelectServer;
  final TextEditingController serverNameController;
  final TextEditingController serverUrlController;
  final Future<void> Function() onAddServer;
  final Future<void> Function() onRemoveSelected;
  final Future<void> Function() onTestConnection;
  final Future<void> Function() onSync;
  final Future<void> Function() onClearCache;
  final String statusText;
  final DateTime? lastSync;
  final bool isSyncing;

  const SettingsDrawer({
    super.key,
    required this.servers,
    required this.selectedKey,
    required this.onSelectServer,
    required this.serverNameController,
    required this.serverUrlController,
    required this.onAddServer,
    required this.onRemoveSelected,
    required this.onTestConnection,
    required this.onSync,
    required this.onClearCache,
    required this.statusText,
    required this.lastSync,
    required this.isSyncing,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          // 背景は画面全体に表示
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          // コンテンツ部分のみSafeAreaでラップ
          SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildServerSection(context),
                const Divider(),
                _buildActionsSection(context),
                const Divider(),
                _buildStatusSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dropdownValue =
        servers.any((s) => s.key == selectedKey) ? selectedKey : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dns, size: 20),
              const SizedBox(width: 8),
              Text('サーバー設定', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: dropdownValue,
            items: servers
                .map((s) => DropdownMenuItem(
                      value: s.key,
                      child: Text('${s.name} (${Uri.parse(s.url).host})'),
                    ))
                .toList(),
            onChanged: (v) => v != null ? onSelectServer(v) : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '選択中のサーバー',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddServerDialog(context),
                  label: const Text('サーバーを追加'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemoveSelected,
                label: const Text('削除'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 20),
              const SizedBox(width: 8),
              Text('操作', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: isSyncing ? null : onTestConnection,
                child: const Text('接続テスト'),
              ),
              FilledButton(
                onPressed: isSyncing ? null : onSync,
                child: const Text('今すぐ同期'),
              ),
              OutlinedButton(
                onPressed: isSyncing ? null : onClearCache,
                child: const Text('キャッシュクリア'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 20),
              const SizedBox(width: 8),
              Text('状態', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('状態: $statusText', style: textTheme.bodyMedium),
                if (lastSync != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '最終同期: ${lastSync.toString().substring(0, 19)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddServerDialog(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: AddServerSheet(
            nameController: serverNameController,
            urlController: serverUrlController,
            onSubmit: onAddServer,
          ),
        );
      },
    );
  }
}
