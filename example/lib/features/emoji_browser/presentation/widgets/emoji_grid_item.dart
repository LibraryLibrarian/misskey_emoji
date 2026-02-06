import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

import '../../../emoji_detail/presentation/emoji_detail_page.dart';

class EmojiGridItem extends StatefulWidget {
  final EmojiRecord record;
  final MisskeyEmojiResolver resolver;
  final bool sensitiveHidden;
  final VoidCallback onToggleSensitive;

  const EmojiGridItem({
    super.key,
    required this.record,
    required this.resolver,
    required this.sensitiveHidden,
    required this.onToggleSensitive,
  });

  @override
  State<EmojiGridItem> createState() => _EmojiGridItemState();
}

class _EmojiGridItemState extends State<EmojiGridItem> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final img = await widget.resolver.resolve(widget.record.name);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmojiDetailPage(record: widget.record, image: img),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(8);

    Widget img = CachedNetworkImage(
      imageUrl: widget.record.url,
      fit: BoxFit.contain,
      memCacheWidth: 64,
      memCacheHeight: 64,
      placeholder: (_, __) => const Center(
          child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))),
      errorWidget: (_, __, ___) =>
          const Icon(Icons.broken_image_outlined, size: 20),
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
    if (widget.sensitiveHidden) {
      img = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: img,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.visibility_off_outlined,
                    size: 18,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '長押し',
                    style: TextStyle(fontSize: 8, color: Colors.white70),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: _handleTap,
        onLongPress:
            widget.record.isSensitive ? widget.onToggleSensitive : null,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Hero(
                      tag: widget.record.name,
                      child: img,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.record.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.6),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
