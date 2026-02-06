import 'package:flutter/material.dart';

class AddServerSheet extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController urlController;
  final Future<void> Function() onSubmit;

  const AddServerSheet({
    super.key,
    required this.nameController,
    required this.urlController,
    required this.onSubmit,
  });

  @override
  State<AddServerSheet> createState() => _AddServerSheetState();
}

class _AddServerSheetState extends State<AddServerSheet> {
  bool _submitting = false;
  late final VoidCallback _nameListener;
  late final VoidCallback _urlListener;

  bool get _canSubmit {
    return widget.nameController.text.trim().isNotEmpty &&
        widget.urlController.text.trim().isNotEmpty &&
        !_submitting;
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit();
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _nameListener = () => setState(() {});
    _urlListener = () => setState(() {});
    widget.nameController.addListener(_nameListener);
    widget.urlController.addListener(_urlListener);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_nameListener);
    widget.urlController.removeListener(_urlListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_link),
                const SizedBox(width: 8),
                const Text('サーバーを追加',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '表示名',
                hintText: '例: misskey.io',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.urlController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleSubmit(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'URL',
                hintText: 'https://example.com',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _canSubmit ? _handleSubmit : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('追加'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
