import '../models/emoji_record.dart';
import 'catalog.dart';

class EmojiSearch {
  final EmojiCatalog catalog;
  EmojiSearch(this.catalog);

  List<EmojiRecord> query(String text, {String? category, int limit = 50}) {
    String norm(String s) => s.trim().toLowerCase();
    final q = norm(text);
    final all = catalog.snapshot().values.toSet().toList();
    final filtered = all.where((e) {
      final hit = e.name.startsWith(q) || e.aliases.any((a) => a.startsWith(q));
      final catOk = category == null || e.category == category;
      return hit && catOk;
    }).take(limit).toList();
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }
}


