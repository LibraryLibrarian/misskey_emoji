import 'dart:async';

import 'package:flutter/material.dart';

class EmojiSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const EmojiSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<EmojiSearchBar> createState() => _EmojiSearchBarState();
}

class _EmojiSearchBarState extends State<EmojiSearchBar> {
  Timer? _debounce;
  late final VoidCallback _controllerListener;

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(text);
    });
  }

  @override
  void initState() {
    super.initState();
    _controllerListener = () => setState(() {});
    widget.controller.addListener(_controllerListener);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_controllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          hintText: '絵文字名で検索（前方一致）',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    widget.controller.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }
}
