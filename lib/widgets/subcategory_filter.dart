import 'package:flutter/material.dart';

/// Distinct sub-category labels from product subcategory strings.
/// null/empty -> 'Uncategorized'. Sorted, 'Uncategorized' last.
List<String> distinctSubcategories(Iterable<String?> raw) {
  final set = <String>{};
  for (final s in raw) {
    set.add((s == null || s.trim().isEmpty) ? 'Uncategorized' : s.trim());
  }
  final list = set.toList()
    ..sort((a, b) {
      if (a == 'Uncategorized') return 1;
      if (b == 'Uncategorized') return -1;
      return a.compareTo(b);
    });
  return list;
}

/// Does a product's subcategory match the active filter?
bool matchesSubFilter(String? productSub, String filter) {
  if (filter == 'All') return true;
  final v = (productSub == null || productSub.trim().isEmpty)
      ? 'Uncategorized'
      : productSub.trim();
  return v == filter;
}

/// Pill row: "All" + each sub-category. Renders nothing when there are
/// fewer than 2 sub-categories (per your spec: don't show noise).
/// Place it ABOVE an Expanded(list) so it stays pinned while the list scrolls.
class SubcategoryFilterBar extends StatelessWidget {
  final List<String> subcategories; // from distinctSubcategories(...)
  final String selected;
  final ValueChanged<String> onSelected;

  const SubcategoryFilterBar({
    super.key,
    required this.subcategories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (subcategories.length < 2) return const SizedBox.shrink();
    final options = ['All', ...subcategories];
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      child: SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: options.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final o = options[i];
            return ChoiceChip(
              label: Text(o),
              selected: o == selected,
              onSelected: (_) => onSelected(o),
            );
          },
        ),
      ),
    );
  }
}