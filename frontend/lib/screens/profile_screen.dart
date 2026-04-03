import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side:
                            BorderSide(color: Colors.grey.withAlpha(30)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _StatRow('Total Expenses',
                                '\$${expenses.totalExpenses.toStringAsFixed(2)}'),
                            const Divider(height: 24),
                            _StatRow('Transactions',
                                '${expenses.expenses.length}'),
                            const Divider(height: 24),
                            _StatRow('Categories Used',
                                '${expenses.expensesByCategory.keys.length}'),
                            const Divider(height: 24),
                            _StatRow('This Month',
                                '\$${expenses.totalThisMonth.toStringAsFixed(2)}'),
                          ],
                        ),
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
                                  builder: (_) =>
                                      const LoginScreen()),
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

  Widget _StatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
