import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;
  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  late String? _selectedCategory;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.expense.amount.toStringAsFixed(2));
    _descriptionController =
        TextEditingController(text: widget.expense.description);
    _notesController = TextEditingController(text: widget.expense.notes ?? '');
    _selectedDate = widget.expense.date;
    _selectedCategory = widget.expense.category;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final updates = <String, dynamic>{};
    final newAmount = double.parse(_amountController.text);
    if (newAmount != widget.expense.amount) updates['amount'] = newAmount;
    if (_descriptionController.text != widget.expense.description) {
      updates['description'] = _descriptionController.text;
    }
    if (_selectedCategory != widget.expense.category) {
      updates['category'] = _selectedCategory;
    }
    if (_selectedDate != widget.expense.date) {
      updates['date'] = _selectedDate.toIso8601String();
    }
    final notes = _notesController.text.isEmpty ? null : _notesController.text;
    if (notes != widget.expense.notes) updates['notes'] = notes ?? '';

    if (updates.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final provider = context.read<ExpenseProvider>();
    final success =
        await provider.updateExpense(widget.expense.expenseId, updates);
    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.error ?? 'Update failed'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense')),
      body: Center(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero amount input
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.grey.shade300, width: 1.5),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: TextFormField(
                      controller: _amountController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        prefixText: '\$ ',
                        prefixStyle: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w700),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter amount';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter description' : null,
                  ),
                  const SizedBox(height: 20),

                  // Category selection - horizontal circle icons
                  Text('Category',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 16),
                      itemCount: ExpenseCategory.defaults.length,
                      itemBuilder: (_, i) {
                        final cat = ExpenseCategory.defaults[i];
                        final selected = _selectedCategory == cat.name;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory =
                              selected ? null : cat.name),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected
                                      ? cat.color
                                      : cat.color.withAlpha(25),
                                ),
                                child: Icon(
                                    ExpenseCategory.getIcon(cat.icon),
                                    color: selected
                                        ? Colors.white
                                        : cat.color,
                                    size: 22),
                              ),
                              const SizedBox(height: 6),
                              Text(cat.name.split(' ').first,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(DateFormat.yMMMd().format(_selectedDate)),
                    trailing: const Icon(Icons.chevron_right),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: GradientButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save, size: 20),
                    SizedBox(width: 8),
                    Text('Update Expense'),
                  ],
                ),
        ),
      ),
    );
  }
}
