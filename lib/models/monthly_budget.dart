class MonthlyBudget {
  final String id;
  final String userId;
  final int year;
  final int month;
  final double totalBudget;
  final Map<String, double> categoryBudgets; // {'food': 400, 'transport': 200}
  final double actualSpent;
  final Map<String, double> categorySpent; // Actual spending per category
  late final double remainingBudget;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyBudget({
    required this.id,
    required this.userId,
    required this.year,
    required this.month,
    required this.totalBudget,
    required this.categoryBudgets,
    this.actualSpent = 0,
    this.categorySpent = const {},
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) {
    remainingBudget = totalBudget - actualSpent;
  }

  // Get remaining budget for a specific category
  double getCategoryRemaining(String category) {
    final budget = categoryBudgets[category] ?? 0;
    final spent = categorySpent[category] ?? 0;
    return budget - spent;
  }

  // Get budget utilization percentage for a category
  double getCategoryUtilization(String category) {
    final budget = categoryBudgets[category] ?? 0;
    final spent = categorySpent[category] ?? 0;
    if (budget == 0) return 0;
    return (spent / budget) * 100;
  }

  // Get overall budget utilization percentage
  double get overallUtilization {
    if (totalBudget == 0) return 0;
    return (actualSpent / totalBudget) * 100;
  }

  // Check if budget is exceeded for a category
  bool isCategoryOverBudget(String category) {
    return getCategoryRemaining(category) < 0;
  }

  // Check if overall budget is exceeded
  bool get isOverBudget => remainingBudget < 0;

  // Get over-budget amount
  double get overBudgetAmount => isOverBudget ? remainingBudget.abs() : 0;

  // Get budget status for a category
  BudgetStatus getCategoryStatus(String category) {
    final utilization = getCategoryUtilization(category);
    if (utilization >= 100) return BudgetStatus.overBudget;
    if (utilization >= 90) return BudgetStatus.warning;
    if (utilization >= 75) return BudgetStatus.approaching;
    return BudgetStatus.good;
  }

  // Get overall budget status
  BudgetStatus get overallStatus {
    final utilization = overallUtilization;
    if (utilization >= 100) return BudgetStatus.overBudget;
    if (utilization >= 90) return BudgetStatus.warning;
    if (utilization >= 75) return BudgetStatus.approaching;
    return BudgetStatus.good;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'year': year,
      'month': month,
      'totalBudget': totalBudget,
      'categoryBudgets': categoryBudgets,
      'actualSpent': actualSpent,
      'categorySpent': categorySpent,
      'remainingBudget': remainingBudget,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MonthlyBudget.fromMap(Map<String, dynamic> map) {
    DateTime createdAt, updatedAt;
    try {
      createdAt = map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now();
      updatedAt = map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now();
    } catch (e) {
      final now = DateTime.now();
      createdAt = now;
      updatedAt = now;
    }
    
    return MonthlyBudget(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      year: map['year'] ?? 0,
      month: map['month'] ?? 0,
      totalBudget: (map['totalBudget'] ?? 0).toDouble(),
      categoryBudgets: Map<String, double>.from(map['categoryBudgets'] ?? {}),
      actualSpent: (map['actualSpent'] ?? 0).toDouble(),
      categorySpent: Map<String, double>.from(map['categorySpent'] ?? {}),
      isActive: map['isActive'] ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  MonthlyBudget copyWith({
    String? id,
    String? userId,
    int? year,
    int? month,
    double? totalBudget,
    Map<String, double>? categoryBudgets,
    double? actualSpent,
    Map<String, double>? categorySpent,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyBudget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      year: year ?? this.year,
      month: month ?? this.month,
      totalBudget: totalBudget ?? this.totalBudget,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      actualSpent: actualSpent ?? this.actualSpent,
      categorySpent: categorySpent ?? this.categorySpent,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum BudgetStatus {
  good,        // < 75% utilized
  approaching, // 75-89% utilized
  warning,     // 90-99% utilized
  overBudget,  // >= 100% utilized
}

extension BudgetStatusExtension on BudgetStatus {
  String get displayName {
    switch (this) {
      case BudgetStatus.good:
        return 'Good';
      case BudgetStatus.approaching:
        return 'Approaching Limit';
      case BudgetStatus.warning:
        return 'Warning';
      case BudgetStatus.overBudget:
        return 'Over Budget';
    }
  }

  String get emoji {
    switch (this) {
      case BudgetStatus.good:
        return '✅';
      case BudgetStatus.approaching:
        return '⚠️';
      case BudgetStatus.warning:
        return '🚨';
      case BudgetStatus.overBudget:
        return '💸';
    }
  }
}
