import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showBudgetDialog(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    final controller = TextEditingController(
        text: provider.monthlyBudget > 0
            ? provider.monthlyBudget.toStringAsFixed(0)
            : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '\$ ',
            labelText: 'Budget amount',
            hintText: 'e.g. 2000',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.setBudget(0);
              Navigator.pop(ctx);
            },
            child: const Text('Remove Budget'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                provider.setBudget(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _exportCsv(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    final csv = provider.exportToCsv();
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'expenses.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expenses exported as CSV')),
    );
  }

  Widget _iconCircle(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(25),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final email = auth.email ?? 'User';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    final totalExpenses = expenses.totalExpenses.toStringAsFixed(2);
    final count = expenses.expenses.length;
    final thisMonth = expenses.totalThisMonth.toStringAsFixed(2);
    final avg = expenses.dailyAverage.toStringAsFixed(2);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Profile', style: TextStyle(fontSize: 18)),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Avatar with gradient border ring
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTokens.primaryGradient,
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        child: Text(initial,
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppTokens.primaryColor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(email,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),

                    // Stats 2x2 grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _StatCard(
                            icon: Icons.account_balance_wallet,
                            label: 'Total',
                            value: '\$$totalExpenses',
                            color: AppTokens.primaryColor),
                        _StatCard(
                            icon: Icons.receipt_outlined,
                            label: 'Transactions',
                            value: '$count',
                            color: const Color(0xFF06B6D4)),
                        _StatCard(
                            icon: Icons.calendar_month,
                            label: 'This Month',
                            value: '\$$thisMonth',
                            color: const Color(0xFF10B981)),
                        _StatCard(
                            icon: Icons.trending_up,
                            label: 'Daily Avg',
                            value: '\$$avg',
                            color: const Color(0xFFF59E0B)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Actions card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.withAlpha(30)),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: _iconCircle(
                                Icons.savings_outlined, Colors.amber),
                            title: const Text('Monthly Budget'),
                            subtitle: Text(expenses.monthlyBudget > 0
                                ? '\$${expenses.monthlyBudget.toStringAsFixed(0)}'
                                : 'Not set'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showBudgetDialog(context),
                          ),
                          const Divider(height: 1, indent: 56),
                          ListTile(
                            leading: _iconCircle(
                                Icons.download_outlined, Colors.blue),
                            title: const Text('Export CSV'),
                            subtitle: Text('$count expenses'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: expenses.expenses.isEmpty
                                ? null
                                : () => _exportCsv(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign out
                    TextButton(
                      onPressed: () async {
                        await auth.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Sign Out',
                          style: TextStyle(color: Colors.red)),
                    ),

                    const SizedBox(height: 8),

                    // Version
                    Text('v1.0.0',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey)),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withAlpha(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(25),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
