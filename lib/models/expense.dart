class Expense {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String? description;
  final String? photoUrl; // Receipt photo
  final DateTime date;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    this.description,
    this.photoUrl,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'category': category,
      'description': description,
      'photoUrl': photoUrl,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? 'Other',
      description: map['description'],
      photoUrl: map['photoUrl'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}