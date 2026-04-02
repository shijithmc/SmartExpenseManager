import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _summary;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get summary => _summary;

  double get totalExpenses => _expenses.fold(0, (sum, e) => sum + e.amount);

  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (var e in _expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _expenses = await ExpenseService.getExpenses();
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSummary({DateTime? startDate, DateTime? endDate}) async {
    try {
      _summary = await ExpenseService.getSummary(
          startDate: startDate, endDate: endDate);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addExpense({
    required double amount,
    required String description,
    String? category,
    required DateTime date,
    String? notes,
    bool autoCategorize = false,
  }) async {
    try {
      final expense = await ExpenseService.createExpense(
        amount: amount,
        description: description,
        category: category,
        date: date,
        notes: notes,
        autoCategorize: autoCategorize,
      );
      _expenses.insert(0, expense);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    try {
      await ExpenseService.deleteExpense(expenseId);
      _expenses.removeWhere((e) => e.expenseId == expenseId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
