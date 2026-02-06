import 'package:flutter/material.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

import 'category_filter.dart';
import 'emoji_grid_item.dart';

class EmojiGrid extends StatefulWidget {
  final PersistentEmojiCatalog? catalog;
  final MisskeyEmojiResolver? resolver;
  final Future<void> Function() onSync;
  final String searchText;
  final int catalogVersion;

  const EmojiGrid({
    super.key,
    required this.catalog,
    required this.resolver,
    required this.onSync,
    required this.searchText,
    required this.catalogVersion,
  });

  @override
  State<EmojiGrid> createState() => _EmojiGridState();
}

class _EmojiGridState extends State<EmojiGrid> {
  static const String _uncategorizedLabel = '未分類';
  static const int _searchLimit = 5000;

  String? _selectedCategory;
  final Set<String> _revealedSensitive = <String>{};

  String _lastQuery = '';
  String? _lastCategory;
  bool _cacheDirty = true;
  PersistentEmojiCatalog? _lastCatalog;
  int _lastCatalogVersion = -1;
  List<EmojiRecord> _cachedItems = [];
  Map<String, int> _cachedCategoryCounts = {};

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    final resolver = widget.resolver;
    final canUse = catalog != null && resolver != null;

    if (!canUse) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dns_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'サーバーを設定してください',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '設定画面からMisskeyサーバーを追加できます',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    _recalculate(catalog);
    final items = _cachedItems;
    final categoryCounts = _cachedCategoryCounts;
    final sortedCategories = categoryCounts.keys.toList()..sort();

    return Column(
      children: [
        CategoryFilter(
          categories: sortedCategories,
          counts: categoryCounts,
          selectedCategory: _selectedCategory,
          onSelected: (value) => setState(() => _selectedCategory = value),
        ),
        const Divider(height: 1),
        Expanded(
          child: _buildEmojiGrid(items, resolver),
        ),
      ],
    );
  }

  void _recalculate(PersistentEmojiCatalog catalog) {
    final searchText = widget.searchText;

    if (_lastCatalog != catalog) {
      _cacheDirty = true;
    }

    if (_lastCatalogVersion != widget.catalogVersion) {
      _cacheDirty = true;
    }

    if (!_cacheDirty &&
        searchText == _lastQuery &&
        _selectedCategory == _lastCategory) {
      return;
    }

    _lastCatalog = catalog;
    _lastCatalogVersion = widget.catalogVersion;
    _lastQuery = searchText;
    _lastCategory = _selectedCategory;
    _cacheDirty = false;

    final text = searchText;
    final List<EmojiRecord> baseList = text.isEmpty
        ? catalog
            .snapshot()
            .entries
            .where((kv) => kv.key == kv.value.name)
            .map((kv) => kv.value)
            .toList()
        : EmojiSearch(catalog).query(text, limit: _searchLimit);

    final Map<String, int> categoryCounts = <String, int>{};
    for (final e in baseList) {
      final c = (e.category == null || e.category!.isEmpty)
          ? _uncategorizedLabel
          : e.category!;
      categoryCounts[c] = (categoryCounts[c] ?? 0) + 1;
    }

    final selected = _selectedCategory;
    final filteredItems = baseList.where((e) {
      if (selected == null) return true;
      if (selected == _uncategorizedLabel) {
        return e.category == null || e.category!.isEmpty;
      }
      return e.category == selected;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    _cachedItems = filteredItems;
    _cachedCategoryCounts = categoryCounts;
  }

  Widget _buildEmojiGrid(
      List<EmojiRecord> items, MisskeyEmojiResolver resolver) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisExtent = screenWidth > 600 ? 120.0 : 96.0;

    return RefreshIndicator(
      onRefresh: () async {
        await widget.onSync();
        if (mounted) {
          setState(() => _cacheDirty = true);
        }
      },
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                const SizedBox(height: 200),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        widget.searchText.isEmpty
                            ? Icons.sync_problem
                            : Icons.search_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.searchText.isEmpty
                            ? '絵文字がありません'
                            : '該当する絵文字がありません',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 200),
              ],
            )
          : GridView.builder(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                top: 8,
                bottom: 88,
              ),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: crossAxisExtent,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final e = items[index];
                final bool sensitiveHidden =
                    e.isSensitive && !_revealedSensitive.contains(e.name);
                return EmojiGridItem(
                  record: e,
                  resolver: resolver,
                  sensitiveHidden: sensitiveHidden,
                  onToggleSensitive: () {
                    setState(() {
                      if (_revealedSensitive.contains(e.name)) {
                        _revealedSensitive.remove(e.name);
                      } else {
                        _revealedSensitive.add(e.name);
                      }
                    });
                  },
                );
              },
            ),
    );
  }
}
