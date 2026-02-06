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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: '絵文字名で検索（前方一致）',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.controller.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }
}
