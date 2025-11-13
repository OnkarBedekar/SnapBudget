import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/monthly_budget.dart';
import '../models/expense.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import 'cache_service.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CacheService _cache = CacheService();

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
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.monthlyBudgetsCollection)
          .doc(budgetId)
          .set(monthlyBudget.toMap());
      
      // Clear cache for this budget
      _cache.remove('budget_$budgetId');
      _cache.clearPattern('budget_${userId}_');
      
      AppLogger.i('Monthly budget saved: $budgetId');
    } catch (e, stackTrace) {
      AppLogger.e('Error setting monthly budget', e, stackTrace);
      rethrow;
    }
  }

  /// Get monthly budget for a specific month (with caching)
  Future<MonthlyBudget?> getMonthlyBudget(int year, int month, {bool useCache = true}) async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final budgetId = '${year}_${month.toString().padLeft(2, '0')}';
      final cacheKey = 'budget_${userId}_$budgetId';

      // Try cache first
      if (useCache) {
        final cached = _cache.get<MonthlyBudget>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Fetch from Firestore (try cache first, then server)
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.monthlyBudgetsCollection)
          .doc(budgetId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (doc.exists) {
        final budget = MonthlyBudget.fromMap(doc.data()!);
        // Cache the result
        _cache.set(cacheKey, budget, ttl: const Duration(minutes: 10));
        return budget;
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.e('Error getting monthly budget', e, stackTrace);
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
      return Stream.value(<MonthlyBudget>[]);
    }

    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.monthlyBudgetsCollection)
        .orderBy('year')
        .orderBy('month')
        .snapshots()
        .map<List<MonthlyBudget>>((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => MonthlyBudget.fromMap(doc.data()))
            .toList();
      } catch (e, stackTrace) {
        AppLogger.e('Error parsing monthly budgets', e, stackTrace);
        return <MonthlyBudget>[];
      }
    }).handleError((error) {
      AppLogger.e('Error in monthly budgets stream', error);
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
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.monthlyBudgetsCollection)
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
      
      // Clear cache for this budget
      _cache.remove('budget_${userId}_$budgetId');
      
      AppLogger.d('Budget spending updated: $budgetId, amount: +$amount');
    } catch (e, stackTrace) {
      AppLogger.e('Error updating budget spending', e, stackTrace);
      rethrow;
    }
  }

  /// Subtract budget spending when expenses are deleted
  Future<void> subtractBudgetSpending({
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
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.monthlyBudgetsCollection)
          .doc(budgetId);

      // Use transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(budgetDoc);
        
        if (snapshot.exists) {
          final data = snapshot.data()!;
          final currentSpent = (data['actualSpent'] ?? 0).toDouble();
          final categorySpent = Map<String, double>.from(data['categorySpent'] ?? {});
          
          // Subtract from totals
          final newActualSpent = (currentSpent - amount).clamp(0.0, double.infinity);
          final newCategorySpent = Map<String, double>.from(categorySpent);
          final currentCategorySpent = (newCategorySpent[category] ?? 0) - amount;
          newCategorySpent[category] = currentCategorySpent.clamp(0.0, double.infinity);
          
          transaction.update(budgetDoc, {
            'actualSpent': newActualSpent,
            'categorySpent': newCategorySpent,
            'remainingBudget': data['totalBudget'] - newActualSpent,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      });
      
      // Clear cache for this budget
      _cache.remove('budget_${userId}_$budgetId');
      
      AppLogger.d('Budget spending subtracted: $budgetId, amount: -$amount');
    } catch (e, stackTrace) {
      AppLogger.e('Error subtracting budget spending', e, stackTrace);
      rethrow;
    }
  }

  /// Update budget spending when expense is modified (handles old vs new values)
  Future<void> updateBudgetSpendingOnEdit({
    required int oldYear,
    required int oldMonth,
    required double oldAmount,
    required String oldCategory,
    required int newYear,
    required int newMonth,
    required double newAmount,
    required String newCategory,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      // If month/year changed, subtract from old month and add to new month
      if (oldYear != newYear || oldMonth != newMonth) {
        // Subtract from old month
        await subtractBudgetSpending(
          year: oldYear,
          month: oldMonth,
          amount: oldAmount,
          category: oldCategory,
        );
        // Add to new month
        await updateBudgetSpending(
          year: newYear,
          month: newMonth,
          amount: newAmount,
          category: newCategory,
        );
      } else {
        // Same month, just update the difference
        final budgetId = '${newYear}_${newMonth.toString().padLeft(2, '0')}';
        final budgetDoc = _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.monthlyBudgetsCollection)
            .doc(budgetId);

        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(budgetDoc);
          
          if (snapshot.exists) {
            final data = snapshot.data()!;
            final currentSpent = (data['actualSpent'] ?? 0).toDouble();
            final categorySpent = Map<String, double>.from(data['categorySpent'] ?? {});
            
            // Calculate difference
            final amountDiff = newAmount - oldAmount;
            final newActualSpent = (currentSpent + amountDiff).clamp(0.0, double.infinity);
            
            // Update category spending
            final newCategorySpent = Map<String, double>.from(categorySpent);
            
            // Subtract from old category
            if (oldCategory != newCategory) {
              final oldCategorySpent = (newCategorySpent[oldCategory] ?? 0) - oldAmount;
              newCategorySpent[oldCategory] = oldCategorySpent.clamp(0.0, double.infinity);
            }
            
            // Add to new category
            final currentNewCategorySpent = (newCategorySpent[newCategory] ?? 0);
            if (oldCategory == newCategory) {
              // Same category, just update the difference
              newCategorySpent[newCategory] = (currentNewCategorySpent + amountDiff).clamp(0.0, double.infinity);
            } else {
              // Different category, add new amount
              newCategorySpent[newCategory] = (currentNewCategorySpent + newAmount).clamp(0.0, double.infinity);
            }
            
            transaction.update(budgetDoc, {
              'actualSpent': newActualSpent,
              'categorySpent': newCategorySpent,
              'remainingBudget': data['totalBudget'] - newActualSpent,
              'updatedAt': DateTime.now().toIso8601String(),
            });
          }
        });
        
        // Clear cache for affected budgets
        _cache.remove('budget_${userId}_$budgetId');
        if (oldYear != newYear || oldMonth != newMonth) {
          final oldBudgetId = '${oldYear}_${oldMonth.toString().padLeft(2, '0')}';
          _cache.remove('budget_${userId}_$oldBudgetId');
        }
        
        AppLogger.d('Budget spending updated on edit: $budgetId');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error updating budget spending on edit', e, stackTrace);
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
