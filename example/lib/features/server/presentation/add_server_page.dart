import 'package:flutter/material.dart';

import '../data/preset_servers.dart';
import '../services/server_manager.dart';

/// サーバー追加ページ
///
/// プリセットサーバー一覧とカスタム入力の2セクションで構成
class AddServerPage extends StatefulWidget {
  final ServerManager manager;

  const AddServerPage({super.key, required this.manager});

  @override
  State<AddServerPage> createState() => _AddServerPageState();
}

class _AddServerPageState extends State<AddServerPage> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  bool _submitting = false;
  bool _showCustomForm = false;

  bool get _canSubmitCustom {
    return _nameController.text.trim().isNotEmpty &&
        _urlController.text.trim().isNotEmpty &&
        !_submitting;
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onTextChanged);
    _urlController.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _urlController.removeListener(_onTextChanged);
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _addPresetServer(PresetServer preset) async {
    setState(() => _submitting = true);
    try {
      final ok = await widget.manager.addServer(preset.name, preset.url);
      if (ok && mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _addCustomServer() async {
    if (!_canSubmitCustom) return;
    setState(() => _submitting = true);
    try {
      final ok = await widget.manager.addServer(
        _nameController.text.trim(),
        _urlController.text.trim(),
      );
      if (ok && mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('サーバーを追加'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // おすすめサーバーセクション
          Text(
            'おすすめサーバー',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'タップするとすぐに追加されます',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...kPresetServers.map((preset) {
            final isAdded = widget.manager.isServerAdded(preset.url);
            return _PresetServerTile(
              preset: preset,
              isAdded: isAdded,
              isLoading: _submitting,
              onTap: isAdded || _submitting
                  ? null
                  : () => _addPresetServer(preset),
            );
          }),
          const SizedBox(height: 24),

          // カスタムサーバーセクション
          Text(
            'カスタムサーバー',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (!_showCustomForm)
            OutlinedButton.icon(
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('URLを入力して追加'),
              onPressed: () => setState(() => _showCustomForm = true),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: '表示名',
                      hintText: '例: my-server',
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.url,
                    onSubmitted: (_) => _addCustomServer(),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'サーバーURL',
                      hintText: 'https://example.com',
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _showCustomForm = false),
                        child: const Text('キャンセル'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _canSubmitCustom ? _addCustomServer : null,
                        child: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('追加'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// プリセットサーバーのListTile
class _PresetServerTile extends StatelessWidget {
  final PresetServer preset;
  final bool isAdded;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PresetServerTile({
    required this.preset,
    required this.isAdded,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: isAdded
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor:
              isAdded ? colorScheme.outline : colorScheme.primaryContainer,
          child: Icon(
            isAdded ? Icons.check : Icons.dns_outlined,
            color: isAdded
                ? colorScheme.onSurfaceVariant
                : colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          preset.name,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: isAdded ? colorScheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: Text(
          preset.description,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: isAdded
            ? Text(
                '追加済み',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : Icon(
                Icons.add_circle_outline,
                color: colorScheme.primary,
              ),
        onTap: onTap,
      ),
    );
  }
}
