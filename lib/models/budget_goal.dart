class BudgetGoal {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String category; // 'savings', 'expense_limit', 'income_target'
  final DateTime startDate;
  final DateTime endDate;
  final String? iconName;
  final int colorValue;
  final DateTime createdAt;

  BudgetGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.category,
    required this.startDate,
    required this.endDate,
    this.iconName,
    required this.colorValue,
    required this.createdAt,
  });

  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount) * 100;
  }

  bool get isCompleted => currentAmount >= targetAmount;

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'category': category,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'iconName': iconName,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BudgetGoal.fromMap(Map<String, dynamic> map) {
    DateTime startDate, endDate, createdAt;
    try {
      final now = DateTime.now();
      startDate = map['startDate'] != null 
          ? DateTime.parse(map['startDate']) 
          : now;
      endDate = map['endDate'] != null 
          ? DateTime.parse(map['endDate']) 
          : now.add(const Duration(days: 30));
      createdAt = map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : now;
    } catch (e) {
      final now = DateTime.now();
      startDate = now;
      endDate = now.add(const Duration(days: 30));
      createdAt = now;
    }
    
    return BudgetGoal(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0).toDouble(),
      category: map['category'] ?? 'savings',
      startDate: startDate,
      endDate: endDate,
      iconName: map['iconName'],
      colorValue: map['colorValue'] ?? 0xFF6C63FF,
      createdAt: createdAt,
    );
  }

  BudgetGoal copyWith({
    String? id,
    String? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? iconName,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return BudgetGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}