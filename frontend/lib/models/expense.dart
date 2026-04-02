class Expense {
  final String expenseId;
  final String userId;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final DateTime createdAt;
  final bool aiCategorized;
  final String? notes;

  Expense({
    required this.expenseId,
    required this.userId,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.createdAt,
    this.aiCategorized = false,
    this.notes,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      expenseId: json['expenseId'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      category: json['category'] ?? 'Other',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      aiCategorized: json['aiCategorized'] ?? false,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expenseId': expenseId,
      'userId': userId,
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'aiCategorized': aiCategorized,
      'notes': notes,
    };
  }
}
