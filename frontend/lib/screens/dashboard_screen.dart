import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/summary_chart.dart';
import '../widgets/projected_spend_card.dart';
import '../widgets/expense_card.dart';
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
        height: 64,
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Expenses'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          if (result == true && mounted) {
            context.read<ExpenseProvider>().loadExpenses();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboard() {
    final email = context.watch<AuthProvider>().email ?? 'User';
    final greeting = _getGreeting();

    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.expenses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.expenses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off,
                      size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Could not load expenses'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => provider.loadExpenses(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadExpenses(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Compact app bar with greeting
              SliverAppBar(
                floating: true,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$greeting,',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey)),
                    Text(email,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => provider.loadExpenses(),
                    tooltip: 'Refresh',
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),

                    // Projected monthly spend card
                    ProjectedSpendCard(
                      totalThisMonth: provider.totalThisMonth,
                      dailyAverage: provider.dailyAverage,
                      projectedMonthlySpend: provider.projectedMonthlySpend,
                      daysElapsed: provider.daysElapsed,
                      daysInMonth: provider.daysInMonth,
                    ),

                    const SizedBox(height: 20),

                    // Quick stats row
                    Row(
                      children: [
                        _QuickStat(
                          icon: Icons.receipt_outlined,
                          label: 'Transactions',
                          value: '${provider.monthlyExpenses.length}',
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        _QuickStat(
                          icon: Icons.category_outlined,
                          label: 'Categories',
                          value: '${provider.categoriesUsedThisMonth}',
                          color: const Color(0xFF4ECDC4),
                        ),
                        const SizedBox(width: 8),
                        _QuickStat(
                          icon: Icons.arrow_upward,
                          label: 'Biggest',
                          value:
                              '\$${provider.biggestExpense.toStringAsFixed(0)}',
                          color: const Color(0xFFFF6B6B),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Spending chart
                    if (provider.expensesByCategory.isNotEmpty) ...[
                      Text('Spending by Category',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SummaryChart(
                          expensesByCategory: provider.expensesByCategory),
                      const SizedBox(height: 24),
                    ],

                    // Recent expenses header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Expenses',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        if (provider.expenses.length > 3)
                          TextButton(
                            onPressed: () =>
                                setState(() => _currentIndex = 1),
                            child: const Text('See All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ]),
                ),
              ),

              // Recent expenses list
              if (provider.expenses.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(32),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No expenses yet',
                              style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Text('Tap + to add your first expense',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= provider.expenses.length ||
                          index >= 5) {
                        return null;
                      }
                      return ExpenseCard(expense: provider.expenses[index]);
                    },
                    childCount:
                        provider.expenses.length > 5 ? 5 : provider.expenses.length,
                  ),
                ),

              // Bottom padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withAlpha(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }
}
