import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';
import '../services/expense_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  bool _autoCategorize = true;
  bool _isSubmitting = false;
  bool _isCategorizing = false;
  String? _aiSuggestion;
  double? _aiConfidence;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _categorizeWithAI() async {
    if (_descriptionController.text.isEmpty) return;

    setState(() => _isCategorizing = true);
    try {
      final result = await ExpenseService.aiCategorize(
        _descriptionController.text,
        amount: double.tryParse(_amountController.text),
      );
      setState(() {
        _aiSuggestion = result['category'];
        _aiConfidence = (result['confidence'] as num?)?.toDouble();
        _selectedCategory = _aiSuggestion;
        _isCategorizing = false;
      });
    } catch (e) {
      setState(() => _isCategorizing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI categorization failed: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<ExpenseProvider>();
    final success = await provider.addExpense(
      amount: double.parse(_amountController.text),
      description: _descriptionController.text,
      category: _selectedCategory,
      date: _selectedDate,
      notes:
          _notesController.text.isEmpty ? null : _notesController.text,
      autoCategorize: _autoCategorize && _selectedCategory == null,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                  if (double.tryParse(v) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: const Icon(Icons.description),
                  border: const OutlineInputBorder(),
                  suffixIcon: _isCategorizing
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.auto_awesome,
                              color: Colors.amber),
                          tooltip: 'AI Categorize',
                          onPressed: _categorizeWithAI,
                        ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a description' : null,
              ),
              if (_aiSuggestion != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withAlpha(76)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI suggests: $_aiSuggestion (${(_aiConfidence! * 100).toStringAsFixed(0)}% confidence)',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Category',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.defaults.map((cat) {
                  final isSelected = _selectedCategory == cat.name;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(cat.name),
                    avatar:
                        Icon(ExpenseCategory.getIcon(cat.icon), size: 18),
                    selectedColor: cat.color.withAlpha(76),
                    onSelected: (selected) {
                      setState(() =>
                          _selectedCategory = selected ? cat.name : null);
                    },
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
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Auto-categorize with AI'),
                subtitle: const Text(
                    'Let AI choose the best category if none selected'),
                value: _autoCategorize,
                onChanged: (v) => setState(() => _autoCategorize = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(
                      _isSubmitting ? 'Saving...' : 'Save Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
