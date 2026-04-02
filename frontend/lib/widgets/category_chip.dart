import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryChip extends StatelessWidget {
  final String categoryName;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const CategoryChip({
    super.key,
    required this.categoryName,
    this.selected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cat =
        ExpenseCategory.defaults.where((c) => c.name == categoryName).firstOrNull;
    final color = cat?.color ?? const Color(0xFFAEB6BF);
    final icon = cat?.icon ?? 'more_horiz';

    return FilterChip(
      selected: selected,
      label: Text(categoryName),
      avatar: Icon(ExpenseCategory.getIcon(icon), size: 18),
      selectedColor: color.withAlpha(76),
      onSelected: onSelected,
    );
  }
}
