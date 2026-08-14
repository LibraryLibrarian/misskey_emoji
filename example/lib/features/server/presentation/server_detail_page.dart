import 'package:flutter/material.dart';

import '../../../core/utils/file_size_formatter.dart';
import '../models/server_entry.dart';
import '../services/server_manager.dart';

/// 個別サーバー詳細ページ
///
/// - 絵文字数の表示
/// - アクティブサーバー切替
/// - 接続テスト
/// - キャッシュクリア
/// - サーバー削除
class ServerDetailPage extends StatefulWidget {
  final ServerManager manager;
  final ServerEntry server;

  const ServerDetailPage({
    super.key,
    required this.manager,
    required this.server,
  });

  @override
  State<ServerDetailPage> createState() => _ServerDetailPageState();
}

class _ServerDetailPageState extends State<ServerDetailPage> {
  int _emojiCount = 0;
  int _dbSize = 0;
  bool _loadingCount = true;
  bool _testing = false;
  String? _testResult;

  ServerManager get _manager => widget.manager;
  String get _serverKey => widget.server.key;
  bool get _isActive => _manager.selectedKey == _serverKey;

  @override
  void initState() {
    super.initState();
    _loadEmojiCount();
  }

  Future<void> _loadEmojiCount() async {
    setState(() => _loadingCount = true);
    try {
      final count = await _manager.getEmojiCountFor(_serverKey);
      final size = await _manager.getDatabaseSizeFor(_serverKey);
      if (mounted) {
        setState(() {
          _emojiCount = count;
          _dbSize = size;
          _loadingCount = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCount = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final ok = await _manager.testConnectionFor(_serverKey);
      if (mounted) {
        setState(() {
          _testing = false;
          _testResult = ok ? '接続OK' : '接続失敗';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testing = false;
          _testResult = '接続失敗: $e';
        });
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('キャッシュクリア'),
        content: Text('${widget.server.name} の絵文字キャッシュを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('クリア'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _manager.clearCacheFor(_serverKey);
    // ファイルシステムの更新を待つ
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadEmojiCount();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('キャッシュをクリアしました')));
    }
  }

  Future<void> _setAsActive() async {
    await _manager.selectServer(_serverKey);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.server.name} を表示サーバーに設定しました')),
      );
    }
  }

  Future<void> _deleteServer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('サーバーを削除'),
        content: Text('${widget.server.name} を削除しますか？\n絵文字キャッシュも合わせて削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _manager.removeServer(_serverKey);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        // サーバーが削除されている場合はpop
        final stillExists = _manager.servers.any((s) => s.key == _serverKey);
        if (!stillExists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop(true);
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final isActive = _isActive;

        return Scaffold(
          appBar: AppBar(title: Text(widget.server.name), centerTitle: true),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // サーバー情報セクション
              _buildInfoSection(colorScheme, textTheme, isActive),
              const SizedBox(height: 24),

              // アクティブサーバー設定ボタン
              _buildSetActiveButton(colorScheme, textTheme, isActive),
              const SizedBox(height: 24),

              // 操作セクション
              _buildActionsSection(colorScheme, textTheme),
              const SizedBox(height: 24),

              // 削除セクション
              _buildDeleteSection(colorScheme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.dns_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.server.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.server.url,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '表示中',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colorScheme.outlineVariant, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.emoji_emotions_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '絵文字数',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (_loadingCount)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  '$_emojiCount 個',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.storage_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'キャッシュ容量',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (_loadingCount)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  _dbSize < 0 ? '取得失敗' : formatFileSize(_dbSize),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _dbSize < 0 ? colorScheme.error : null,
                  ),
                ),
            ],
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _testResult == '接続OK'
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 20,
                  color: _testResult == '接続OK'
                      ? colorScheme.primary
                      : colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  _testResult!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: _testResult == '接続OK'
                        ? colorScheme.primary
                        : colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetActiveButton(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isActive,
  ) {
    return FilledButton.icon(
      onPressed: isActive ? null : _setAsActive,
      icon: Icon(isActive ? Icons.check_circle : Icons.swap_horiz, size: 20),
      label: Text(isActive ? '現在の表示サーバーです' : '表示サーバーに設定'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Widget _buildActionsSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '操作',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: _testing ? null : _testConnection,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: _testing
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('テスト中...'),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi, size: 20),
                    SizedBox(width: 12),
                    Text('接続テスト'),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _clearCache,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, size: 20),
              SizedBox(width: 12),
              Text('キャッシュクリア'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteSection(ColorScheme colorScheme) {
    return OutlinedButton(
      onPressed: _deleteServer,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        foregroundColor: colorScheme.error,
        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_forever, size: 20),
          SizedBox(width: 12),
          Text('サーバーを削除'),
        ],
      ),
    );
  }
}
