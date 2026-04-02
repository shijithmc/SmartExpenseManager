import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/category.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onDelete;

  const ExpenseCard({super.key, required this.expense, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = ExpenseCategory.getCategoryColor(expense.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(50),
          child: Icon(
            ExpenseCategory.getIcon(
              ExpenseCategory.defaults
                      .where((c) => c.name == expense.category)
                      .firstOrNull
                      ?.icon ??
                  'more_horiz',
            ),
            color: color,
          ),
        ),
        title: Row(
          children: [
            Expanded(
                child: Text(expense.description,
                    overflow: TextOverflow.ellipsis)),
            if (expense.aiCategorized)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.auto_awesome,
                    size: 16, color: Colors.amber.shade600),
              ),
          ],
        ),
        subtitle: Text(
          '${expense.category} - ${DateFormat.yMMMd().format(expense.date)}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
