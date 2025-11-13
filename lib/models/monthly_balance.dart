class MonthlyBalance {
  final String id;
  final String userId;
  final int year;
  final int month;
  final double income;
  final double expenses;
  final double netBalance;
  final double carryoverFromPrevious; // Previous month's remaining balance
  final double totalSavings; // Cumulative savings
  final double actualHoursWorked; // Track actual hours for this month
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyBalance({
    required this.id,
    required this.userId,
    required this.year,
    required this.month,
    required this.income,
    required this.expenses,
    required this.netBalance,
    this.carryoverFromPrevious = 0,
    this.totalSavings = 0,
    this.actualHoursWorked = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get the remaining balance for this month (including carryover)
  double get remainingBalance => carryoverFromPrevious + netBalance;

  // Get cumulative savings (previous savings + current month's positive balance)
  double get cumulativeSavings => totalSavings + (netBalance > 0 ? netBalance : 0);

  // Check if this month had debt (negative balance)
  bool get hadDebt => netBalance < 0;

  // Get debt amount (negative balance)
  double get debtAmount => netBalance < 0 ? netBalance.abs() : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'year': year,
      'month': month,
      'income': income,
      'expenses': expenses,
      'netBalance': netBalance,
      'carryoverFromPrevious': carryoverFromPrevious,
      'totalSavings': totalSavings,
      'actualHoursWorked': actualHoursWorked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MonthlyBalance.fromMap(Map<String, dynamic> map) {
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
    
    return MonthlyBalance(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      year: map['year'] ?? 0,
      month: map['month'] ?? 0,
      income: (map['income'] ?? 0).toDouble(),
      expenses: (map['expenses'] ?? 0).toDouble(),
      netBalance: (map['netBalance'] ?? 0).toDouble(),
      carryoverFromPrevious: (map['carryoverFromPrevious'] ?? 0).toDouble(),
      totalSavings: (map['totalSavings'] ?? 0).toDouble(),
      actualHoursWorked: (map['actualHoursWorked'] ?? 0).toDouble(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  MonthlyBalance copyWith({
    String? id,
    String? userId,
    int? year,
    int? month,
    double? income,
    double? expenses,
    double? netBalance,
    double? carryoverFromPrevious,
    double? totalSavings,
    double? actualHoursWorked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyBalance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      year: year ?? this.year,
      month: month ?? this.month,
      income: income ?? this.income,
      expenses: expenses ?? this.expenses,
      netBalance: netBalance ?? this.netBalance,
      carryoverFromPrevious: carryoverFromPrevious ?? this.carryoverFromPrevious,
      totalSavings: totalSavings ?? this.totalSavings,
      actualHoursWorked: actualHoursWorked ?? this.actualHoursWorked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
