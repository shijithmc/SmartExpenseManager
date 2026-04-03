import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';
import '../widgets/expense_card.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String? _filterCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final filtered = _filterCategory == null
            ? provider.expenses
            : provider.expenses
                .where((e) => e.category == _filterCategory)
                .toList();

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text('Expenses (${filtered.length})',
                  style: const TextStyle(fontSize: 18)),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filterCategory == null,
                        onSelected: (_) =>
                            setState(() => _filterCategory = null),
                      ),
                      const SizedBox(width: 6),
                      ...ExpenseCategory.defaults.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _FilterChip(
                              label: cat.name,
                              selected: _filterCategory == cat.name,
                              color: cat.color,
                              onSelected: (_) => setState(() =>
                                  _filterCategory =
                                      _filterCategory == cat.name
                                          ? null
                                          : cat.name),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No expenses found',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final expense = filtered[index];
                    return Dismissible(
                      key: Key(expense.expenseId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delete,
                            color: Colors.red.shade400),
                      ),
                      confirmDismiss: (_) => showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Expense'),
                          content: const Text('Delete this expense?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                child: const Text('Delete',
                                    style:
                                        TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                      onDismissed: (_) {
                        provider.deleteExpense(expense.expenseId);
                      },
                      child: ExpenseCard(
                        expense: expense,
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Expense'),
                              content:
                                  const Text('Delete this expense?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Delete',
                                        style: TextStyle(
                                            color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            provider.deleteExpense(expense.expenseId);
                          }
                        },
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final ValueChanged<bool>? onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: color?.withAlpha(60),
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
