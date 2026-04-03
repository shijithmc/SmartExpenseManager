import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/summary_chart.dart';
import 'add_expense_screen.dart';
import 'expense_list_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      const ExpenseListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          if (result == true && mounted) {
            context.read<ExpenseProvider>().loadExpenses();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildDashboard() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to load expenses',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => provider.loadExpenses(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Dashboard'),
              floating: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.loadExpenses(),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Expenses',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(
                              '\$${provider.totalExpenses.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor),
                            ),
                            const SizedBox(height: 4),
                            Text('${provider.expenses.length} transactions',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Spending by Category',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    if (provider.expenses.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: SummaryChart(
                            expensesByCategory: provider.expensesByCategory),
                      )
                    else
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                  'No expenses yet. Tap + to add one!'))),
                    const SizedBox(height: 24),
                    Text('Recent Expenses',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ...provider.expenses.take(5).map((expense) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withAlpha(25),
                              child: Icon(Icons.receipt,
                                  color: Theme.of(context).primaryColor),
                            ),
                            title: Text(expense.description),
                            subtitle: Text(
                                '${expense.category} - ${expense.date.month}/${expense.date.day}/${expense.date.year}'),
                            trailing: Text(
                              '\$${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        )),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
