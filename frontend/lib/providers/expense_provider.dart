import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _summary;
  double _monthlyBudget = 0;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get summary => _summary;
  double get monthlyBudget => _monthlyBudget;

  double get totalExpenses => _expenses.fold(0, (sum, e) => sum + e.amount);

  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (var e in _expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  // --- Monthly projection properties ---

  List<Expense> get monthlyExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
  }

  double get totalThisMonth =>
      monthlyExpenses.fold(0, (sum, e) => sum + e.amount);

  int get daysElapsed => DateTime.now().day;

  int get daysInMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }

  double get dailyAverage {
    if (daysElapsed == 0) return 0;
    return totalThisMonth / daysElapsed;
  }

  double get projectedMonthlySpend => dailyAverage * daysInMonth;

  double get biggestExpense {
    if (monthlyExpenses.isEmpty) return 0;
    return monthlyExpenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
  }

  int get categoriesUsedThisMonth =>
      monthlyExpenses.map((e) => e.category).toSet().length;

  double get budgetRemaining =>
      _monthlyBudget > 0 ? _monthlyBudget - totalThisMonth : 0;

  double get budgetProgress =>
      _monthlyBudget > 0 ? (totalThisMonth / _monthlyBudget).clamp(0.0, 1.5) : 0;

  bool get isOverBudget => _monthlyBudget > 0 && totalThisMonth > _monthlyBudget;

  // --- Last 7 days spending ---

  Map<String, double> get last7DaysSpending {
    final map = <String, double>{};
    final now = DateTime.now();
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.month}/${day.day}';
      map[key] = 0;
    }
    for (var e in _expenses) {
      final diff = now.difference(e.date).inDays;
      if (diff >= 0 && diff < 7) {
        final key = '${e.date.month}/${e.date.day}';
        map[key] = (map[key] ?? 0) + e.amount;
      }
    }
    return map;
  }

  // --- Budget ---

  Future<void> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    _monthlyBudget = prefs.getDouble('monthly_budget') ?? 0;
    notifyListeners();
  }

  Future<void> setBudget(double amount) async {
    _monthlyBudget = amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', amount);
    notifyListeners();
  }

  // --- Data loading ---

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

  Future<bool> updateExpense(String expenseId, Map<String, dynamic> updates) async {
    try {
      final expense = await ExpenseService.updateExpense(expenseId, updates);
      final idx = _expenses.indexWhere((e) => e.expenseId == expenseId);
      if (idx != -1) _expenses[idx] = expense;
      _expenses.sort((a, b) => b.date.compareTo(a.date));
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

  // --- CSV Export ---

  String exportToCsv() {
    final buf = StringBuffer();
    buf.writeln('Date,Description,Category,Amount,Notes,AI Categorized');
    for (var e in _expenses) {
      final desc = e.description.replaceAll(',', ';');
      final notes = (e.notes ?? '').replaceAll(',', ';');
      buf.writeln(
          '${e.date.toIso8601String().split('T')[0]},$desc,${e.category},${e.amount.toStringAsFixed(2)},$notes,${e.aiCategorized}');
    }
    return buf.toString();
  }
}
