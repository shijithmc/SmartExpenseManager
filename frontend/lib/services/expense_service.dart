import 'dart:convert';
import '../models/expense.dart';
import 'api_service.dart';

class ExpenseService {
  static Future<List<Expense>> getExpenses() async {
    final response = await ApiService.get('expense');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Expense.fromJson(e)).toList();
    }
    throw Exception('Failed to load expenses');
  }

  static Future<Expense> createExpense({
    required double amount,
    required String description,
    String? category,
    required DateTime date,
    String? notes,
    bool autoCategorize = false,
  }) async {
    final response = await ApiService.post('expense', {
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
      'autoCategorize': autoCategorize,
    });
    if (response.statusCode == 201) {
      return Expense.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create expense');
  }

  static Future<Expense> updateExpense(
      String expenseId, Map<String, dynamic> updates) async {
    final response = await ApiService.put('expense/$expenseId', updates);
    if (response.statusCode == 200) {
      return Expense.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update expense');
  }

  static Future<void> deleteExpense(String expenseId) async {
    final response = await ApiService.delete('expense/$expenseId');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete expense');
    }
  }

  static Future<Map<String, dynamic>> getSummary(
      {DateTime? startDate, DateTime? endDate}) async {
    var endpoint = 'expense/summary';
    final params = <String>[];
    if (startDate != null) {
      params.add('startDate=${startDate.toIso8601String()}');
    }
    if (endDate != null) {
      params.add('endDate=${endDate.toIso8601String()}');
    }
    if (params.isNotEmpty) endpoint += '?${params.join('&')}';

    final response = await ApiService.get(endpoint);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load summary');
  }

  static Future<Map<String, dynamic>> aiCategorize(String description,
      {double? amount}) async {
    final response = await ApiService.post('ai/categorize', {
      'description': description,
      if (amount != null) 'amount': amount,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to categorize');
  }
}
