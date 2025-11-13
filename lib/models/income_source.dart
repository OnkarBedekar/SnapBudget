class IncomeSource {
  final String id;
  final String userId;
  final String jobName;
  final double hourlyRate;
  final List<int> payDates; // [7, 22] for 7th and 22nd
  final double hoursWorked;
  final double targetHours; // e.g., 80 hours per period
  final DateTime createdAt;

  IncomeSource({
    required this.id,
    required this.userId,
    required this.jobName,
    required this.hourlyRate,
    required this.payDates,
    this.hoursWorked = 0,
    this.targetHours = 80,
    required this.createdAt,
  });

  // Calculate projected income for current period
  double get projectedIncome => targetHours * hourlyRate;

  // Calculate earned so far
  double get earnedSoFar => hoursWorked * hourlyRate;

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'jobName': jobName,
      'hourlyRate': hourlyRate,
      'payDates': payDates,
      'hoursWorked': hoursWorked,
      'targetHours': targetHours,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firebase Map
  factory IncomeSource.fromMap(Map<String, dynamic> map) {
    DateTime createdAt;
    try {
      createdAt = map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    return IncomeSource(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      jobName: map['jobName'] ?? '',
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      payDates: List<int>.from(map['payDates'] ?? []),
      hoursWorked: (map['hoursWorked'] ?? 0).toDouble(),
      targetHours: (map['targetHours'] ?? 80).toDouble(),
      createdAt: createdAt,
    );
  }

  // Create a copy with updated values
  IncomeSource copyWith({
    String? id,
    String? userId,
    String? jobName,
    double? hourlyRate,
    List<int>? payDates,
    double? hoursWorked,
    double? targetHours,
    DateTime? createdAt,
  }) {
    return IncomeSource(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      jobName: jobName ?? this.jobName,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      payDates: payDates ?? this.payDates,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      targetHours: targetHours ?? this.targetHours,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}