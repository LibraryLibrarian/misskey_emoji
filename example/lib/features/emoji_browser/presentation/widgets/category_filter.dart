import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final Map<String, int> counts;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  const CategoryFilter({
    super.key,
    required this.categories,
    required this.counts,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final allCount = counts.values.fold(0, (sum, count) => sum + count);
    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: Text('ALL ($allCount)'),
            selected: selectedCategory == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$c (${counts[c] ?? 0})'),
                  selected: selectedCategory == c,
                  onSelected: (_) => onSelected(c),
                ),
              )),
        ],
      ),
    );
  }
}
