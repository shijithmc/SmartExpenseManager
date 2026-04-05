import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/summary_chart.dart';
import '../widgets/projected_spend_card.dart';
import '../widgets/spending_trend_chart.dart';
import '../widgets/expense_card.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';
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
      final provider = context.read<ExpenseProvider>();
      provider.loadExpenses();
      provider.loadBudget();
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
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

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
                  Icon(Icons.cloud_off, size: 56, color: Colors.grey.shade400),
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
              SliverAppBar(
                floating: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: AppTokens.primaryColor,
                    child: Text(initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
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
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),

                    // Hero: Projected monthly spend card
                    ProjectedSpendCard(
                      totalThisMonth: provider.totalThisMonth,
                      dailyAverage: provider.dailyAverage,
                      projectedMonthlySpend: provider.projectedMonthlySpend,
                      daysElapsed: provider.daysElapsed,
                      daysInMonth: provider.daysInMonth,
                    ),

                    const SizedBox(height: 24),

                    // Budget inline thin bar (if budget set)
                    if (provider.monthlyBudget > 0) ...[
                      _BudgetBar(
                        budget: provider.monthlyBudget,
                        spent: provider.totalThisMonth,
                        remaining: provider.budgetRemaining,
                        progress: provider.budgetProgress,
                        isOver: provider.isOverBudget,
                      ),
                      const SizedBox(height: 40),
                    ],

                    // Quick stats - horizontal scroll
                    Text('Quick Stats',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickStat(
                              icon: Icons.receipt_outlined,
                              label: 'Transactions',
                              value: '${provider.monthlyExpenses.length}',
                              color: const Color(0xFF6366F1)),
                          const SizedBox(width: 8),
                          _QuickStat(
                              icon: Icons.category_outlined,
                              label: 'Categories',
                              value: '${provider.categoriesUsedThisMonth}',
                              color: const Color(0xFF4ECDC4)),
                          const SizedBox(width: 8),
                          _QuickStat(
                              icon: Icons.arrow_upward,
                              label: 'Biggest',
                              value:
                                  '\$${provider.biggestExpense.toStringAsFixed(0)}',
                              color: const Color(0xFFFF6B6B)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 7-day spending trend
                    if (provider.expenses.isNotEmpty) ...[
                      Text('Last 7 Days',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SpendingTrendChart(
                          last7DaysSpending: provider.last7DaysSpending),
                      const SizedBox(height: 40),
                    ],

                    // Category chart
                    if (provider.expensesByCategory.isNotEmpty) ...[
                      Text('Spending by Category',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SummaryChart(
                          expensesByCategory: provider.expensesByCategory),
                      const SizedBox(height: 40),
                    ],

                    // Recent expenses
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Expenses',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600)),
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

              // Recent expenses list (tappable to edit)
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
                              style:
                                  TextStyle(color: Colors.grey.shade500)),
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
                      if (index >= provider.expenses.length || index >= 5) {
                        return null;
                      }
                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditExpenseScreen(
                                  expense: provider.expenses[index]),
                            ),
                          );
                          if (result == true && mounted) {
                            provider.loadExpenses();
                          }
                        },
                        child: ExpenseCard(
                            expense: provider.expenses[index]),
                      );
                    },
                    childCount: provider.expenses.length > 5
                        ? 5
                        : provider.expenses.length,
                  ),
                ),
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

class _BudgetBar extends StatelessWidget {
  final double budget;
  final double spent;
  final double remaining;
  final double progress;
  final bool isOver;

  const _BudgetBar({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.progress,
    required this.isOver,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOver ? Colors.red : AppTokens.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Budget',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
              Text(
                isOver
                    ? 'Over by \$${(spent - budget).toStringAsFixed(2)}'
                    : '\$${remaining.toStringAsFixed(2)} remaining',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: color.withAlpha(25),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
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
    return SizedBox(
      width: 120,
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
