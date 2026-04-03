import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../models/category.dart';

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$ ',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter amount';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter description' : null,
                  ),
                  const SizedBox(height: 16),
                  Text('Category',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ExpenseCategory.defaults.map((cat) {
                      return FilterChip(
                        selected: _selectedCategory == cat.name,
                        label: Text(cat.name),
                        avatar:
                            Icon(ExpenseCategory.getIcon(cat.icon), size: 18),
                        selectedColor: cat.color.withAlpha(76),
                        onSelected: (s) =>
                            setState(() => _selectedCategory = s ? cat.name : null),
                      );
                    }).toList(),
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
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label:
                          Text(_isSubmitting ? 'Saving...' : 'Update Expense'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
