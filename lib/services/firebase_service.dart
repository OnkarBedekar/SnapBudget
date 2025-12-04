import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income_source.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/budget_goal.dart';
import '../models/monthly_balance.dart';
import '../models/monthly_budget.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import 'monthly_balance_service.dart';
import 'budget_service.dart';
import 'notification_service.dart';
import 'cache_service.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Service instances (lazy initialization to avoid circular dependency)
  MonthlyBalanceService? _balanceService;
  BudgetService? _budgetService;
  final CacheService _cache = CacheService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  bool get isAuthenticated => _auth.currentUser != null;

  // Lazy getters for services
  MonthlyBalanceService get balanceService {
    _balanceService ??= MonthlyBalanceService();
    return _balanceService!;
  }

  BudgetService get budgetService {
    _budgetService ??= BudgetService();
    return _budgetService!;
  }

  // ==================== INCOME OPERATIONS ====================
  
  // Add new income source
  Future<void> addIncomeSource(IncomeSource income) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      AppLogger.i('Adding income source: ${income.id}');
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.incomeSourcesCollection)
          .doc(income.id)
          .set(income.toMap());
      AppLogger.i('Income source added successfully: ${income.id}');
    } catch (e, stackTrace) {
      AppLogger.e('Error adding income source', e, stackTrace);
      rethrow;
    }
  }

  // Get all income sources
  Stream<List<IncomeSource>> getIncomeSources() {
    if (currentUserId == null) {
      AppLogger.w('getIncomeSources called but user not authenticated');
      return Stream.value(<IncomeSource>[]);
    }
    
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.incomeSourcesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map<List<IncomeSource>>((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => IncomeSource.fromMap(doc.data()))
            .toList();
      } catch (e, stackTrace) {
        AppLogger.e('Error parsing income sources', e, stackTrace);
        return <IncomeSource>[];
      }
    }).handleError((error) {
      AppLogger.e('Error in income sources stream', error);
    });
  }

  // Update income source (e.g., add hours worked)
  Future<void> updateIncomeSource(IncomeSource income) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      AppLogger.i('Updating income source: ${income.id}');
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.incomeSourcesCollection)
          .doc(income.id)
          .update(income.toMap());
      AppLogger.i('Income source updated successfully: ${income.id}');
    } catch (e, stackTrace) {
      AppLogger.e('Error updating income source', e, stackTrace);
      rethrow;
    }
  }

  // Delete income source
  Future<void> deleteIncomeSource(String incomeId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      if (incomeId.isEmpty) {
        throw ArgumentError('Income ID cannot be empty');
      }
      
      AppLogger.i('Deleting income source: $incomeId');
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.incomeSourcesCollection)
          .doc(incomeId)
          .delete();
      AppLogger.i('Income source deleted successfully: $incomeId');
    } catch (e, stackTrace) {
      AppLogger.e('Error deleting income source', e, stackTrace);
      rethrow;
    }
  }

  // ==================== EXPENSE OPERATIONS ====================

  // Add new expense with budget tracking
  Future<void> addExpense(Expense expense) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      // Validate expense
      if (expense.amount <= 0) {
        throw ArgumentError('Expense amount must be greater than 0');
      }
      if (expense.amount > AppConstants.maxExpenseAmount) {
        throw ArgumentError('Expense amount exceeds maximum allowed');
      }
      
      AppLogger.i('Adding expense: ${expense.id}, amount: ${expense.amount}');
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.expensesCollection)
          .doc(expense.id)
          .set(expense.toMap());
      
      // Clear expense-related cache
      _cache.clearPattern('total_expenses_${currentUserId}_');

      // Update budget spending
      try {
        await budgetService.updateBudgetSpending(
          year: expense.date.year,
          month: expense.date.month,
          amount: expense.amount,
          category: expense.category,
        );
      } catch (e, stackTrace) {
        // Log but don't fail the expense addition
        AppLogger.w('Failed to update budget spending', e, stackTrace);
      }
      
      AppLogger.i('Expense added successfully: ${expense.id}');
    } catch (e, stackTrace) {
      AppLogger.e('Error adding expense', e, stackTrace);
      rethrow;
    }
  }

  // Get expenses for current pay period (optimized with limit)
  Stream<List<Expense>> getExpenses({DateTime? startDate, DateTime? endDate, int? limit}) {
    if (currentUserId == null) {
      AppLogger.w('getExpenses called but user not authenticated');
      return Stream.value(<Expense>[]);
    }
    
    Query query = _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.expensesCollection);

    if (startDate != null && endDate != null) {
      query = query
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String());
    }

    // Apply limit if specified (useful for recent expenses)
    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }

    return query.orderBy('date', descending: true).snapshots().map<List<Expense>>((snapshot) {
      try {
        return snapshot.docs
            .map((doc) {
              try {
                return Expense.fromMap(doc.data() as Map<String, dynamic>);
              } catch (e, stackTrace) {
                AppLogger.e('Error parsing expense: ${doc.id}', e, stackTrace);
                return null;
              }
            })
            .where((expense) => expense != null)
            .cast<Expense>()
            .toList();
      } catch (e, stackTrace) {
        AppLogger.e('Error parsing expenses', e, stackTrace);
        return <Expense>[];
      }
    }).handleError((error) {
      AppLogger.e('Error in expenses stream', error);
    });
  }

  // Get total expenses for a period (with caching)
  Future<double> getTotalExpenses({DateTime? startDate, DateTime? endDate}) async {
    try {
      if (currentUserId == null) {
        AppLogger.w('getTotalExpenses called but user not authenticated');
        return 0.0;
      }
      
      // Create cache key based on date range
      final cacheKey = 'total_expenses_${currentUserId}_${startDate?.toIso8601String() ?? 'all'}_${endDate?.toIso8601String() ?? 'all'}';
      
      // Try cache first
      final cached = _cache.get<double>(cacheKey);
      if (cached != null) {
        return cached;
      }
      
      Query query = _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.expensesCollection);

      if (startDate != null && endDate != null) {
        query = query
            .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
            .where('date', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      // Use cache-first source for offline support
      final snapshot = await query.get(const GetOptions(source: Source.serverAndCache));
      double total = 0;
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0).toDouble();
          if (amount > 0) {
            total += amount;
          }
        } catch (e, stackTrace) {
          AppLogger.w('Error parsing expense amount in getTotalExpenses', e, stackTrace);
        }
      }
      
      // Cache the result (shorter TTL for totals since they change frequently)
      _cache.set(cacheKey, total, ttl: const Duration(minutes: 2));
      
      return total;
    } catch (e, stackTrace) {
      AppLogger.e('Error getting total expenses', e, stackTrace);
      return 0.0;
    }
  }

  // Update expense
  Future<void> updateExpense(Expense expense, {Expense? oldExpense}) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      AppLogger.i('Updating expense: ${expense.id}');
      
      // Get old expense data if not provided
      Expense? oldExpenseData = oldExpense;
      if (oldExpenseData == null) {
        final expenseDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(currentUserId)
            .collection(AppConstants.expensesCollection)
            .doc(expense.id)
            .get();
        
        if (expenseDoc.exists) {
          final expenseData = expenseDoc.data() as Map<String, dynamic>;
          oldExpenseData = Expense.fromMap(expenseData);
        }
      }

      // Update the expense in Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.expensesCollection)
          .doc(expense.id)
          .update(expense.toMap());
      
      // Clear expense-related cache
      _cache.clearPattern('total_expenses_${currentUserId}_');

      // Update budget spending if expense changed
      if (oldExpenseData != null) {
        final amountChanged = oldExpenseData.amount != expense.amount;
        final categoryChanged = oldExpenseData.category != expense.category;
        final dateChanged = oldExpenseData.date.year != expense.date.year || 
                           oldExpenseData.date.month != expense.date.month;
        
        if (amountChanged || categoryChanged || dateChanged) {
          try {
            await budgetService.updateBudgetSpendingOnEdit(
              oldYear: oldExpenseData.date.year,
              oldMonth: oldExpenseData.date.month,
              oldAmount: oldExpenseData.amount,
              oldCategory: oldExpenseData.category,
              newYear: expense.date.year,
              newMonth: expense.date.month,
              newAmount: expense.amount,
              newCategory: expense.category,
            );
          } catch (e, stackTrace) {
            // Log but don't fail the expense update
            AppLogger.w('Failed to update budget spending on edit', e, stackTrace);
          }
        }
      }

      AppLogger.i('Expense updated successfully: ${expense.id}');
    } catch (e, stackTrace) {
      AppLogger.e('Error updating expense', e, stackTrace);
      rethrow;
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      if (expenseId.isEmpty) {
        throw ArgumentError('Expense ID cannot be empty');
      }
      
      AppLogger.i('Deleting expense: $expenseId');
      
      // Get the expense data before deleting it
      final expenseDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.expensesCollection)
          .doc(expenseId)
          .get();

      if (!expenseDoc.exists) {
        AppLogger.w('Expense not found: $expenseId');
        return;
      }

      final expenseData = expenseDoc.data() as Map<String, dynamic>;
      final expense = Expense.fromMap(expenseData);

      // Delete the expense
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.expensesCollection)
          .doc(expenseId)
          .delete();
      
      // Clear expense-related cache
      _cache.clearPattern('total_expenses_${currentUserId}_');

      // Update budget spending by subtracting the deleted expense amount
      try {
        await budgetService.subtractBudgetSpending(
          year: expense.date.year,
          month: expense.date.month,
          amount: expense.amount,
          category: expense.category,
        );
      } catch (e, stackTrace) {
        // Log but don't fail the expense deletion
        AppLogger.w('Failed to update budget spending on delete', e, stackTrace);
      }

      // Update expense limit goals by subtracting the deleted expense amount
      await _updateExpenseLimitGoalsOnDelete(expense);

      AppLogger.i('Expense deleted and all values updated: $expenseId');
    } catch (e, stackTrace) {
      AppLogger.e('Error deleting expense', e, stackTrace);
      rethrow;
    }
  }

  // ==================== BUDGET OPERATIONS ====================

  // Save budget
  Future<void> saveBudget(Budget budget) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      AppLogger.i('Saving budget: ${budget.id}');
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.budgetsCollection)
          .doc(budget.id)
          .set(budget.toMap());
      AppLogger.i('Budget saved successfully: ${budget.id}');
    } catch (e, stackTrace) {
      AppLogger.e('Error saving budget', e, stackTrace);
      rethrow;
    }
  }

  // Get current budget
  Stream<Budget?> getCurrentBudget() {
    if (currentUserId == null) {
      AppLogger.w('getCurrentBudget called but user not authenticated');
      return Stream.value(null);
    }
    
    final now = DateTime.now();
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.budgetsCollection)
        .where('startDate', isLessThanOrEqualTo: now.toIso8601String())
        .where('endDate', isGreaterThanOrEqualTo: now.toIso8601String())
        .snapshots()
        .map<Budget?>((snapshot) {
      try {
        if (snapshot.docs.isEmpty) return null;
        return Budget.fromMap(snapshot.docs.first.data());
      } catch (e, stackTrace) {
        AppLogger.e('Error parsing budget', e, stackTrace);
        return null;
      }
    }).handleError((error) {
      AppLogger.e('Error in budget stream', error);
    });
  }

  // ==================== BUDGET GOAL OPERATIONS ====================

  // Add new budget goal
  Future<void> addBudgetGoal(BudgetGoal goal) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      AppLogger.i('Adding budget goal: ${goal.id}');
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.budgetGoalsCollection)
          .doc(goal.id)
          .set(goal.toMap());
      AppLogger.i('Budget goal added successfully: ${goal.id}');
    } catch (e, stackTrace) {
      AppLogger.e('Error adding budget goal', e, stackTrace);
      rethrow;
    }
  }

  // Get all budget goals
  Stream<List<BudgetGoal>> getBudgetGoals() {
    if (currentUserId == null) {
      AppLogger.w('getBudgetGoals called but user not authenticated');
      return Stream.value(<BudgetGoal>[]);
    }
    
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.budgetGoalsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map<List<BudgetGoal>>((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => BudgetGoal.fromMap(doc.data()))
            .toList();
      } catch (e, stackTrace) {
        AppLogger.e('Error parsing budget goals', e, stackTrace);
        return <BudgetGoal>[];
      }
    }).handleError((error) {
      AppLogger.e('Error in budget goals stream', error);
    });
  }

  // Update budget goal
  Future<void> updateBudgetGoal(BudgetGoal goal) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      AppLogger.i('Updating budget goal: ${goal.id}');
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.budgetGoalsCollection)
          .doc(goal.id)
          .update(goal.toMap());
      AppLogger.i('Budget goal updated successfully: ${goal.id}');
    } catch (e, stackTrace) {
      AppLogger.e('Error updating budget goal', e, stackTrace);
      rethrow;
    }
  }

  // Delete budget goal
  Future<void> deleteBudgetGoal(String goalId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      if (goalId.isEmpty) {
        throw ArgumentError('Goal ID cannot be empty');
      }
      
      AppLogger.i('Deleting budget goal: $goalId');
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.budgetGoalsCollection)
          .doc(goalId)
          .delete();
      AppLogger.i('Budget goal deleted successfully: $goalId');
    } catch (e, stackTrace) {
      AppLogger.e('Error deleting budget goal', e, stackTrace);
      rethrow;
    }
  }

  // Get active budget goals (not completed and not expired)
  Future<List<BudgetGoal>> getActiveBudgetGoals() async {
    try {
      if (currentUserId == null) {
        AppLogger.w('getActiveBudgetGoals called but user not authenticated');
        return [];
      }
      
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.budgetGoalsCollection)
          .where('endDate', isGreaterThanOrEqualTo: now.toIso8601String())
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return BudgetGoal.fromMap(doc.data());
            } catch (e, stackTrace) {
              AppLogger.e('Error parsing budget goal: ${doc.id}', e, stackTrace);
              return null;
            }
          })
          .where((goal) => goal != null && !goal.isCompleted)
          .cast<BudgetGoal>()
          .toList();
    } catch (e, stackTrace) {
      AppLogger.e('Error getting active budget goals', e, stackTrace);
      return [];
    }
  }

  // Update expense limit goals automatically when expense is added
  Future<void> updateExpenseLimitGoals(Expense expense) async {
    try {
      AppLogger.i('Starting expense limit goal update for expense: ${expense.amount}');
      final activeGoals = await getActiveBudgetGoals();
      AppLogger.d('Found ${activeGoals.length} active goals');
      
      if (activeGoals.isEmpty) {
        AppLogger.d('No active goals found');
        return;
      }
      
      bool updatedAnyGoal = false;
      for (var goal in activeGoals) {
        AppLogger.d('Checking goal: ${goal.name}, category: ${goal.category}');
        if (goal.category == 'expense_limit') {
          // Only update goals that were created BEFORE or ON THE SAME DAY as the expense date
          // This prevents historical expenses from affecting new goals
          final goalDate = DateTime(goal.createdAt.year, goal.createdAt.month, goal.createdAt.day);
          final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
          
          if (goalDate.isBefore(expenseDate) || goalDate.isAtSameMomentAs(expenseDate)) {
            final oldAmount = goal.currentAmount;
            final newCurrentAmount = goal.currentAmount + expense.amount;
            
            AppLogger.d('Updating goal: ${goal.name} from $oldAmount to $newCurrentAmount (+${expense.amount})');
            
            final updatedGoal = goal.copyWith(currentAmount: newCurrentAmount);
            await updateBudgetGoal(updatedGoal);
            updatedAnyGoal = true;
            
            AppLogger.i('Successfully updated expense goal: ${goal.name}');
            
            // Check if we should show notification after update
            await _checkExpenseGoalNotification(updatedGoal);
          } else {
            AppLogger.d('Skipping goal: ${goal.name} - goal created after expense date');
          }
        } else {
          AppLogger.d('Skipping goal: ${goal.name} - not an expense_limit goal');
        }
      }
      
      if (updatedAnyGoal) {
        AppLogger.i('Successfully updated expense limit goals');
      } else {
        AppLogger.d('No expense limit goals were updated');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error updating expense limit goals', e, stackTrace);
    }
  }

  // Update expense limit goals when expense is deleted (subtract amount)
  Future<void> _updateExpenseLimitGoalsOnDelete(Expense expense) async {
    try {
      AppLogger.i('Starting expense limit goal update for deleted expense: ${expense.amount}');
      final activeGoals = await getActiveBudgetGoals();
      AppLogger.d('Found ${activeGoals.length} active goals');
      
      if (activeGoals.isEmpty) {
        AppLogger.d('No active goals found');
        return;
      }
      
      bool updatedAnyGoal = false;
      for (var goal in activeGoals) {
        AppLogger.d('Checking goal: ${goal.name}, category: ${goal.category}');
        if (goal.category == 'expense_limit') {
          // Only update goals that were created BEFORE or ON THE SAME DAY as the expense date
          // This prevents historical expenses from affecting new goals
          final goalDate = DateTime(goal.createdAt.year, goal.createdAt.month, goal.createdAt.day);
          final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
          
          if (goalDate.isBefore(expenseDate) || goalDate.isAtSameMomentAs(expenseDate)) {
            final oldAmount = goal.currentAmount;
            final newCurrentAmount = goal.currentAmount - expense.amount;
            
            // Ensure current amount doesn't go below 0
            final finalAmount = newCurrentAmount < 0 ? 0.0 : newCurrentAmount.toDouble();
            
            AppLogger.d('Updating goal: ${goal.name} from $oldAmount to $finalAmount (-${expense.amount})');
            
            final updatedGoal = goal.copyWith(currentAmount: finalAmount);
            await updateBudgetGoal(updatedGoal);
            updatedAnyGoal = true;
            
            AppLogger.i('Successfully updated expense goal: ${goal.name}');
            
            // Check if we should show notification after update
            await _checkExpenseGoalNotification(updatedGoal);
          } else {
            AppLogger.d('Skipping goal: ${goal.name} - goal created after expense date');
          }
        } else {
          AppLogger.d('Skipping goal: ${goal.name} - not an expense_limit goal');
        }
      }
      
      if (updatedAnyGoal) {
        AppLogger.i('Successfully updated expense limit goals after deletion');
      } else {
        AppLogger.d('No expense limit goals were updated');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error updating expense limit goals on delete', e, stackTrace);
    }
  }

  // Check and show notification for expense goal progress
  Future<void> _checkExpenseGoalNotification(BudgetGoal goal) async {
    try {
      if (goal.category == 'expense_limit') {
        double progress = (goal.currentAmount / goal.targetAmount) * 100;
        
        // Show notification at different thresholds
        if (progress >= 80) {
          await NotificationService().showExpenseGoalAlert(
            goal.name,
            goal.currentAmount,
            goal.targetAmount,
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error checking expense goal notification', e, stackTrace);
    }
  }

  // ==================== AUTH OPERATIONS ====================

  // Sign in anonymously (for now, we'll add proper auth later)
  Future<void> signInAnonymously() async {
    try {
      AppLogger.i('Signing in anonymously');
      await _auth.signInAnonymously();
      AppLogger.i('Signed in anonymously successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Error signing in anonymously', e, stackTrace);
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      AppLogger.i('Signing out user');
      await _auth.signOut();
      AppLogger.i('User signed out successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Error signing out', e, stackTrace);
      rethrow;
    }
  }

  // ==================== ENHANCED FEATURES ====================

  // Monthly Balance Operations
  Future<void> saveMonthlyBalance({
    required int year,
    required int month,
    required double income,
    required double expenses,
    required double actualHoursWorked,
  }) async {
    return await balanceService.saveMonthlyBalance(
      year: year,
      month: month,
      income: income,
      expenses: expenses,
      actualHoursWorked: actualHoursWorked,
    );
  }

  Future<MonthlyBalance?> getMonthlyBalance(int year, int month) async {
    return await balanceService.getMonthlyBalance(year, month);
  }

  Stream<List<MonthlyBalance>> getMonthlyBalances() {
    return balanceService.getMonthlyBalances();
  }

  Future<Map<String, dynamic>> getCurrentMonthBalanceWithCarryover({
    required List<IncomeSource> incomeSources,
    required List<Expense> expenses,
    required int year,
    required int month,
  }) async {
    return await balanceService.getCurrentMonthBalanceWithCarryover(
      incomeSources: incomeSources,
      expenses: expenses,
      year: year,
      month: month,
    );
  }

  Future<Map<String, dynamic>> getMonthOverMonthComparison(int year, int month) async {
    return await balanceService.getMonthOverMonthComparison(year, month);
  }

  // Budget Operations
  Future<void> setMonthlyBudget({
    required int year,
    required int month,
    required double totalBudget,
    required Map<String, double> categoryBudgets,
  }) async {
    return await budgetService.setMonthlyBudget(
      year: year,
      month: month,
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
    );
  }

  Future<MonthlyBudget?> getMonthlyBudget(int year, int month, {bool useCache = true}) async {
    return await budgetService.getMonthlyBudget(year, month, useCache: useCache);
  }

  Future<MonthlyBudget?> getCurrentMonthBudget() async {
    return await budgetService.getCurrentMonthBudget();
  }

  Stream<List<MonthlyBudget>> getMonthlyBudgets() {
    return budgetService.getMonthlyBudgets();
  }

  Future<Map<String, dynamic>> getCurrentMonthBudgetStatus({
    required List<Expense> expenses,
  }) async {
    return await budgetService.getCurrentMonthBudgetStatus(expenses: expenses);
  }

  Future<Map<String, double>> getBudgetRecommendations({
    required List<Expense> lastThreeMonthsExpenses,
  }) async {
    return await budgetService.getBudgetRecommendations(
      lastThreeMonthsExpenses: lastThreeMonthsExpenses,
    );
  }

  Future<List<String>> getBudgetWarnings({
    required List<Expense> currentMonthExpenses,
  }) async {
    return await budgetService.getBudgetWarnings(
      currentMonthExpenses: currentMonthExpenses,
    );
  }
}