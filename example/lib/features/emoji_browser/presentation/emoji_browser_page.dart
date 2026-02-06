import 'dart:async';

import 'package:flutter/material.dart';

import '../../server/models/server_entry.dart';
import '../../server/presentation/settings_page.dart';
import '../../server/services/server_manager.dart';
import 'widgets/category_filter.dart';
import 'widgets/emoji_grid.dart';
import 'widgets/emoji_search_bar.dart';

class EmojiBrowserPage extends StatefulWidget {
  const EmojiBrowserPage({super.key});

  @override
  State<EmojiBrowserPage> createState() => _EmojiBrowserPageState();
}

class _EmojiBrowserPageState extends State<EmojiBrowserPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  late final AnimationController _appBarAnimationController;
  late final Animation<double> _appBarAnimation;
  final ServerManager _manager = ServerManager();
  String _searchText = '';
  String? _selectedCategory;
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _appBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // 初期状態は表示
    );
    _appBarAnimation = CurvedAnimation(
      parent: _appBarAnimationController,
      curve: Curves.easeInOut,
    );
    _scrollController.addListener(_onScroll);
    unawaited(_manager.init().then((_) => _autoSyncIfNeeded()));
  }

  Future<void> _autoSyncIfNeeded() async {
    final catalog = _manager.currentContext?.catalog;
    if (catalog == null) return;

    // カタログが空の場合は自動同期
    final snapshot = catalog.snapshot();
    if (snapshot.isEmpty && !_manager.isSyncing) {
      await _manager.sync();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _appBarAnimationController.dispose();
    unawaited(_manager.close());
    _manager.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;

    // スクロール量が小さい場合は無視（感度調整）
    if (delta.abs() < 5.0) {
      return;
    }

    // 下にスクロール（AppBar非表示）
    if (delta > 0 && currentOffset > 100) {
      if (_appBarAnimationController.value > 0) {
        _appBarAnimationController.animateTo(0.0);
      }
    }
    // 上にスクロール（AppBar表示）
    else if (delta < 0) {
      if (_appBarAnimationController.value < 1) {
        _appBarAnimationController.animateTo(1.0);
      }
    }

    _lastScrollOffset = currentOffset;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        final selectedServer = _manager.selectedServer ??
            (_manager.servers.isNotEmpty
                ? _manager.servers.first
                : const ServerEntry(name: '未選択', url: ''));

        final appBarHeight = _manager.isSyncing ? 60.0 : 56.0;
        final statusBarHeight = MediaQuery.of(context).padding.top;
        final totalAppBarHeight = appBarHeight + statusBarHeight;

        return Scaffold(
          body: Stack(
            children: [
              // メインコンテンツ（CategoryFilter + EmojiGrid）
              Positioned.fill(
                child: Column(
                  children: [
                    // AppBarとCategoryFilterのスペースを確保
                    AnimatedBuilder(
                      animation: _appBarAnimation,
                      builder: (context, child) {
                        return SizedBox(
                          height: _appBarAnimation.value * appBarHeight,
                        );
                      },
                    ),
                    // CategoryFilter（常に表示）
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: _buildCategoryFilterSection(),
                      ),
                    ),
                    // EmojiGrid
                    Expanded(
                      child: EmojiGrid(
                        catalog: _manager.currentContext?.catalog,
                        resolver: _manager.currentContext?.resolver,
                        onSync: _manager.sync,
                        searchText: _searchText,
                        selectedCategory: _selectedCategory,
                        catalogVersion:
                            _manager.catalogVersionFor(_manager.selectedKey),
                        scrollController: _scrollController,
                      ),
                    ),
                  ],
                ),
              ),
              // アニメーション付きAppBar
              AnimatedBuilder(
                animation: _appBarAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: 0,
                    right: 0,
                    top: -totalAppBarHeight * (1 - _appBarAnimation.value),
                    child: child!,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 56,
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Misskey Emoji SampleApp',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      selectedServer.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.sync),
                                onPressed: _manager.isSyncing ||
                                        _manager.currentContext?.catalog == null
                                    ? null
                                    : _manager.sync,
                                tooltip: '同期',
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        if (_manager.isSyncing)
                          const SizedBox(
                            height: 4,
                            child: LinearProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // 下部の検索バー
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: FloatingActionButton(
                          onPressed: () => _navigateToSettings(context),
                          tooltip: '設定',
                          child: const Icon(Icons.settings),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: EmojiSearchBar(
                          controller: _searchController,
                          onChanged: (text) {
                            setState(() => _searchText = text.trim());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilterSection() {
    final catalog = _manager.currentContext?.catalog;

    if (catalog == null) {
      return const SizedBox(height: 48);
    }

    // カテゴリーとカウントを計算
    final snapshot = catalog.snapshot();
    final baseList = _searchText.isEmpty
        ? snapshot.entries
            .where((kv) => kv.key == kv.value.name)
            .map((kv) => kv.value)
            .toList()
        : [];

    final Map<String, int> categoryCounts = <String, int>{};
    for (final e in baseList) {
      final c =
          (e.category == null || e.category!.isEmpty) ? '未分類' : e.category!;
      categoryCounts[c] = (categoryCounts[c] ?? 0) + 1;
    }

    final sortedCategories = categoryCounts.keys.toList()..sort();

    return CategoryFilter(
      categories: sortedCategories,
      counts: categoryCounts,
      selectedCategory: _selectedCategory,
      onSelected: (value) => setState(() => _selectedCategory = value),
    );
  }

  Future<void> _navigateToSettings(BuildContext context) async {
    final hadServer = _manager.selectedServer != null;
    final previousKey = _manager.selectedKey;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(manager: _manager),
      ),
    );

    // 設定画面から戻った後の自動同期処理
    final hasServerNow = _manager.selectedServer != null;
    final catalog = _manager.currentContext?.catalog;
    final serverChanged = _manager.selectedKey != previousKey;

    if (!hasServerNow || catalog == null) return;

    if (!hadServer) {
      // サーバーが新規に追加された場合
      unawaited(_manager.sync());
      return;
    }

    if (serverChanged) {
      // アクティブサーバーが変更された場合は必ず同期
      unawaited(_manager.sync());
      return;
    }

    // 同じサーバーでもカタログが空なら同期
    final snapshot = catalog.snapshot();
    if (snapshot.isEmpty) {
      unawaited(_manager.sync());
    }
  }
}
