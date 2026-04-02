import 'package:flutter/material.dart';

class ExpenseCategory {
  final String name;
  final String icon;
  final Color color;

  ExpenseCategory({
    required this.name,
    required this.icon,
    required this.color,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'more_horiz',
      color: Color(
          int.parse((json['color'] as String).replaceFirst('#', '0xFF'))),
    );
  }

  static List<ExpenseCategory> defaults = [
    ExpenseCategory(
        name: 'Food & Dining',
        icon: 'restaurant',
        color: const Color(0xFFFF6B6B)),
    ExpenseCategory(
        name: 'Transportation',
        icon: 'directions_car',
        color: const Color(0xFF4ECDC4)),
    ExpenseCategory(
        name: 'Shopping',
        icon: 'shopping_bag',
        color: const Color(0xFF45B7D1)),
    ExpenseCategory(
        name: 'Bills & Utilities',
        icon: 'receipt_long',
        color: const Color(0xFF96CEB4)),
    ExpenseCategory(
        name: 'Entertainment',
        icon: 'movie',
        color: const Color(0xFFFFEAA7)),
    ExpenseCategory(
        name: 'Healthcare',
        icon: 'local_hospital',
        color: const Color(0xFFDDA0DD)),
    ExpenseCategory(
        name: 'Travel', icon: 'flight', color: const Color(0xFF98D8C8)),
    ExpenseCategory(
        name: 'Education', icon: 'school', color: const Color(0xFFF7DC6F)),
    ExpenseCategory(
        name: 'Personal', icon: 'person', color: const Color(0xFFBB8FCE)),
    ExpenseCategory(
        name: 'Other', icon: 'more_horiz', color: const Color(0xFFAEB6BF)),
  ];

  static IconData getIcon(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'movie':
        return Icons.movie;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'flight':
        return Icons.flight;
      case 'school':
        return Icons.school;
      case 'person':
        return Icons.person;
      default:
        return Icons.more_horiz;
    }
  }

  static Color getCategoryColor(String categoryName) {
    final cat =
        defaults.where((c) => c.name == categoryName).firstOrNull;
    return cat?.color ?? const Color(0xFFAEB6BF);
  }
}
