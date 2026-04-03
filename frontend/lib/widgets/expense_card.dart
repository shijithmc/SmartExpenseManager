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
    final iconName = ExpenseCategory.defaults
            .where((c) => c.name == expense.category)
            .firstOrNull
            ?.icon ??
        'more_horiz';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withAlpha(30)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Color accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withAlpha(30),
                      child: Icon(
                        ExpenseCategory.getIcon(iconName),
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  expense.description.isEmpty
                                      ? expense.category
                                      : expense.description,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14),
                                ),
                              ),
                              if (expense.aiCategorized)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Icons.auto_awesome,
                                      size: 14,
                                      color: Colors.amber.shade600),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${expense.category} \u00b7 ${DateFormat('MMM d').format(expense.date)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    if (onDelete != null)
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: Colors.red.shade300, size: 18),
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
