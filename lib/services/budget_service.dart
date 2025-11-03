import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/monthly_budget.dart';
import '../models/expense.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Create or update monthly budget
  Future<void> setMonthlyBudget({
    required int year,
    required int month,
    required double totalBudget,
    required Map<String, double> categoryBudgets,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final now = DateTime.now();
      final budgetId = '${year}_${month.toString().padLeft(2, '0')}';

      // Get existing budget to preserve actual spending data
      final existingBudget = await getMonthlyBudget(year, month);
      
      final monthlyBudget = MonthlyBudget(
        id: budgetId,
        userId: userId,
        year: year,
        month: month,
        totalBudget: totalBudget,
        categoryBudgets: categoryBudgets,
        actualSpent: existingBudget?.actualSpent ?? 0,
        categorySpent: existingBudget?.categorySpent ?? {},
        isActive: true,
        createdAt: existingBudget?.createdAt ?? now,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('monthly_budgets')
          .doc(budgetId)
          .set(monthlyBudget.toMap());
          
    } catch (e) {
      print('Error setting monthly budget: $e');
      rethrow;
    }
  }

  /// Get monthly budget for a specific month
  Future<MonthlyBudget?> getMonthlyBudget(int year, int month) async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final budgetId = '${year}_${month.toString().padLeft(2, '0')}';
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('monthly_budgets')
          .doc(budgetId)
          .get();

      if (doc.exists) {
        return MonthlyBudget.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting monthly budget: $e');
      return null;
    }
  }

  /// Get current month's budget
  Future<MonthlyBudget?> getCurrentMonthBudget() async {
    final now = DateTime.now();
    return await getMonthlyBudget(now.year, now.month);
  }

  /// Get all monthly budgets (for analytics)
  Stream<List<MonthlyBudget>> getMonthlyBudgets() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('monthly_budgets')
        .orderBy('year')
        .orderBy('month')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MonthlyBudget.fromMap(doc.data()))
          .toList();
    });
  }

  /// Update budget spending when expenses are added
  Future<void> updateBudgetSpending({
    required int year,
    required int month,
    required double amount,
    required String category,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final budgetId = '${year}_${month.toString().padLeft(2, '0')}';
      final budgetDoc = _firestore
          .collection('users')
          .doc(userId)
          .collection('monthly_budgets')
          .doc(budgetId);

      // Use transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(budgetDoc);
        
        if (snapshot.exists) {
          final data = snapshot.data()!;
          final currentSpent = (data['actualSpent'] ?? 0).toDouble();
          final categorySpent = Map<String, double>.from(data['categorySpent'] ?? {});
          
          // Update totals
          final newActualSpent = currentSpent + amount;
          final newCategorySpent = Map<String, double>.from(categorySpent);
          newCategorySpent[category] = (newCategorySpent[category] ?? 0) + amount;
          
          transaction.update(budgetDoc, {
            'actualSpent': newActualSpent,
            'categorySpent': newCategorySpent,
            'remainingBudget': data['totalBudget'] - newActualSpent,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      });
    } catch (e) {
      print('Error updating budget spending: $e');
      rethrow;
    }
  }

  /// Calculate budget status for current month
  Future<Map<String, dynamic>> getCurrentMonthBudgetStatus({
    required List<Expense> expenses,
  }) async {
    final now = DateTime.now();
    final budget = await getMonthlyBudget(now.year, now.month);
    
    if (budget == null) {
      return {
        'hasBudget': false,
        'totalSpent': expenses.fold(0.0, (sum, expense) => sum + expense.amount),
        'categorySpent': _calculateCategorySpending(expenses),
      };
    }

    // Calculate actual spending from expenses
    final totalSpent = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final categorySpent = _calculateCategorySpending(expenses);

    // Update budget with current spending
    final updatedBudget = budget.copyWith(
      actualSpent: totalSpent,
      categorySpent: categorySpent,
    );

    return {
      'hasBudget': true,
      'budget': updatedBudget,
      'totalSpent': totalSpent,
      'remainingBudget': updatedBudget.remainingBudget,
      'overBudgetAmount': updatedBudget.overBudgetAmount,
      'overallStatus': updatedBudget.overallStatus,
      'categoryStatuses': updatedBudget.categoryBudgets.map((category, _) {
        return MapEntry(category, updatedBudget.getCategoryStatus(category));
      }),
    };
  }

  /// Get budget recommendations based on spending history
  Future<Map<String, double>> getBudgetRecommendations({
    required List<Expense> lastThreeMonthsExpenses,
  }) async {
    final categoryAverages = <String, double>{};
    
    // Calculate average spending per category over last 3 months
    for (final expense in lastThreeMonthsExpenses) {
      categoryAverages[expense.category] = 
          (categoryAverages[expense.category] ?? 0) + expense.amount;
    }

    // Calculate monthly averages
    final totalMonths = 3.0; // Assuming we have 3 months of data
    categoryAverages.forEach((category, total) {
      categoryAverages[category] = total / totalMonths;
    });

    // Add 20% buffer to averages for recommendations
    final recommendations = <String, double>{};
    categoryAverages.forEach((category, average) {
      recommendations[category] = average * 1.2; // 20% buffer
    });

    return recommendations;
  }

  /// Check if user should receive budget warnings
  Future<List<String>> getBudgetWarnings({
    required List<Expense> currentMonthExpenses,
  }) async {
    final warnings = <String>[];
    final budgetStatus = await getCurrentMonthBudgetStatus(expenses: currentMonthExpenses);
    
    if (!budgetStatus['hasBudget']) return warnings;

    final budget = budgetStatus['budget'] as MonthlyBudget;
    final categoryStatuses = budgetStatus['categoryStatuses'] as Map<String, BudgetStatus>;

    // Check overall budget
    if (budget.overallStatus == BudgetStatus.warning) {
      warnings.add('⚠️ You\'ve used ${budget.overallUtilization.toStringAsFixed(0)}% of your monthly budget');
    } else if (budget.overallStatus == BudgetStatus.overBudget) {
      warnings.add('🚨 You\'ve exceeded your monthly budget by \$${budget.overBudgetAmount.toStringAsFixed(2)}');
    }

    // Check category budgets
    categoryStatuses.forEach((category, status) {
      if (status == BudgetStatus.warning) {
        warnings.add('⚠️ ${category} category is at ${budget.getCategoryUtilization(category).toStringAsFixed(0)}% of budget');
      } else if (status == BudgetStatus.overBudget) {
        warnings.add('🚨 ${category} category is over budget by \$${budget.getCategoryRemaining(category).abs().toStringAsFixed(2)}');
      }
    });

    return warnings;
  }

  /// Private helper methods
  Map<String, double> _calculateCategorySpending(List<Expense> expenses) {
    final categorySpent = <String, double>{};
    for (final expense in expenses) {
      categorySpent[expense.category] = 
          (categorySpent[expense.category] ?? 0) + expense.amount;
    }
    return categorySpent;
  }
}
