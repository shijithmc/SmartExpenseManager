import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
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
            border: OutlineInputBorder(),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final expenses = context.watch<ExpenseProvider>();

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
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.person,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(auth.email ?? 'User',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),

                    // Stats card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.withAlpha(30)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _statRow('Total Expenses',
                                '\$${expenses.totalExpenses.toStringAsFixed(2)}'),
                            const Divider(height: 24),
                            _statRow('Transactions',
                                '${expenses.expenses.length}'),
                            const Divider(height: 24),
                            _statRow('Categories Used',
                                '${expenses.expensesByCategory.keys.length}'),
                            const Divider(height: 24),
                            _statRow('This Month',
                                '\$${expenses.totalThisMonth.toStringAsFixed(2)}'),
                            const Divider(height: 24),
                            _statRow('Daily Average',
                                '\$${expenses.dailyAverage.toStringAsFixed(2)}'),
                            const Divider(height: 24),
                            _statRow(
                                'Monthly Budget',
                                expenses.monthlyBudget > 0
                                    ? '\$${expenses.monthlyBudget.toStringAsFixed(0)}'
                                    : 'Not set'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showBudgetDialog(context),
                        icon: const Icon(Icons.savings_outlined, size: 18),
                        label: Text(expenses.monthlyBudget > 0
                            ? 'Change Budget'
                            : 'Set Monthly Budget'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: expenses.expenses.isEmpty
                            ? null
                            : () => _exportCsv(context),
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Export as CSV'),
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
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
                        icon: const Icon(Icons.logout,
                            color: Colors.red, size: 18),
                        label: const Text('Sign Out',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
