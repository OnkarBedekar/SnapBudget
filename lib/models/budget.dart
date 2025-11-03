class Budget {
  final String id;
  final String userId;
  final double totalBudget;
  final Map<String, double> categoryBudgets; // {'food': 400, 'transport': 200}
  final DateTime startDate;
  final DateTime endDate;

  Budget({
    required this.id,
    required this.userId,
    required this.totalBudget,
    required this.categoryBudgets,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'totalBudget': totalBudget,
      'categoryBudgets': categoryBudgets,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      totalBudget: (map['totalBudget'] ?? 0).toDouble(),
      categoryBudgets: Map<String, double>.from(map['categoryBudgets'] ?? {}),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
    );
  }
}
