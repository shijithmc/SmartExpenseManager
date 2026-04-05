import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_card.dart';
import 'edit_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String? _filterCategory;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        var filtered = _filterCategory == null
            ? provider.expenses
            : provider.expenses
                .where((e) => e.category == _filterCategory)
                .toList();

        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          filtered = filtered
              .where((e) =>
                  e.description.toLowerCase().contains(q) ||
                  e.category.toLowerCase().contains(q) ||
                  e.amount.toStringAsFixed(2).contains(q) ||
                  (e.notes ?? '').toLowerCase().contains(q))
              .toList();
        }

        // Build date-grouped flat list
        final List<dynamic> groupedItems = [];
        String? lastDateLabel;
        for (final expense in filtered) {
          final label = _getDateLabel(expense.date);
          if (label != lastDateLabel) {
            groupedItems.add(label);
            lastDateLabel = label;
          }
          groupedItems.add(expense);
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadExpenses(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                title: Text('Expenses (${filtered.length})',
                    style: const TextStyle(fontSize: 18)),
              ),

              // Always-visible search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),

              // Filter chips
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
                        Text(
                            _searchQuery.isNotEmpty
                                ? 'No results for "$_searchQuery"'
                                : 'No expenses found',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = groupedItems[index];

                      // Date group header
                      if (item is String) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      }

                      // Expense card
                      final expense = item as Expense;
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
                          child:
                              Icon(Icons.delete, color: Colors.red.shade400),
                        ),
                        confirmDismiss: (_) => _confirmDelete(context),
                        onDismissed: (_) =>
                            provider.deleteExpense(expense.expenseId),
                        child: GestureDetector(
                          onTap: () async {
                            final result =
                                await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditExpenseScreen(expense: expense),
                              ),
                            );
                            if (result == true && context.mounted) {
                              provider.loadExpenses();
                            }
                          },
                          child: ExpenseCard(
                            expense: expense,
                            onDelete: () async {
                              final confirm =
                                  await _confirmDelete(context);
                              if (confirm == true) {
                                provider.deleteExpense(expense.expenseId);
                              }
                            },
                          ),
                        ),
                      );
                    },
                    childCount: groupedItems.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Delete this expense?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
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
