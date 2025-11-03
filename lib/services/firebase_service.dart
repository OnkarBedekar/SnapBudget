import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income_source.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/budget_goal.dart';
import '../models/monthly_balance.dart';
import '../models/monthly_budget.dart';
import 'monthly_balance_service.dart';
import 'budget_service.dart';
import 'notification_service.dart';

class FirebaseService {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Service instances (lazy initialization to avoid circular dependency)
  MonthlyBalanceService? _balanceService;
  BudgetService? _budgetService;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

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
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('income_sources')
          .doc(income.id)
          .set(income.toMap());
    } catch (e) {
      print('Error adding income source: $e');
      rethrow;
    }
  }

  // Get all income sources
  Stream<List<IncomeSource>> getIncomeSources() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('income_sources')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IncomeSource.fromMap(doc.data()))
          .toList();
    });
  }

  // Update income source (e.g., add hours worked)
  Future<void> updateIncomeSource(IncomeSource income) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('income_sources')
          .doc(income.id)
          .update(income.toMap());
    } catch (e) {
      print('Error updating income source: $e');
      rethrow;
    }
  }

  // Delete income source
  Future<void> deleteIncomeSource(String incomeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('income_sources')
          .doc(incomeId)
          .delete();
    } catch (e) {
      print('Error deleting income source: $e');
      rethrow;
    }
  }

  // ==================== EXPENSE OPERATIONS ====================

  // Add new expense with budget tracking
  Future<void> addExpense(Expense expense) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .doc(expense.id)
          .set(expense.toMap());

      // Update budget spending
      await budgetService.updateBudgetSpending(
        year: expense.date.year,
        month: expense.date.month,
        amount: expense.amount,
        category: expense.category,
      );
    } catch (e) {
      print('Error adding expense: $e');
      rethrow;
    }
  }

  // Get expenses for current pay period
  Stream<List<Expense>> getExpenses({DateTime? startDate, DateTime? endDate}) {
    Query query = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('expenses');

    if (startDate != null && endDate != null) {
      query = query
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String());
    }

    return query.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  // Get total expenses for a period
  Future<double> getTotalExpenses({DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses');

      if (startDate != null && endDate != null) {
        query = query
            .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
            .where('date', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.get();
      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
      }
      return total;
    } catch (e) {
      print('Error getting total expenses: $e');
      return 0;
    }
  }

  // Update expense
  Future<void> updateExpense(Expense expense) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .doc(expense.id)
          .update(expense.toMap());
    } catch (e) {
      print('Error updating expense: $e');
      rethrow;
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      // Get the expense data before deleting it
      final expenseDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .doc(expenseId)
          .get();

      if (!expenseDoc.exists) {
        print('Expense not found: $expenseId');
        return;
      }

      final expenseData = expenseDoc.data() as Map<String, dynamic>;
      final expense = Expense.fromMap(expenseData);

      // Delete the expense
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .doc(expenseId)
          .delete();

      // Update expense limit goals by subtracting the deleted expense amount
      await _updateExpenseLimitGoalsOnDelete(expense);

      print('✅ Expense deleted and goals updated');
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }

  // ==================== BUDGET OPERATIONS ====================

  // Save budget
  Future<void> saveBudget(Budget budget) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('budgets')
          .doc(budget.id)
          .set(budget.toMap());
    } catch (e) {
      print('Error saving budget: $e');
      rethrow;
    }
  }

  // Get current budget
  Stream<Budget?> getCurrentBudget() {
    final now = DateTime.now();
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('budgets')
        .where('startDate', isLessThanOrEqualTo: now.toIso8601String())
        .where('endDate', isGreaterThanOrEqualTo: now.toIso8601String())
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Budget.fromMap(snapshot.docs.first.data());
    });
  }

  // ==================== BUDGET GOAL OPERATIONS ====================

  // Add new budget goal
  Future<void> addBudgetGoal(BudgetGoal goal) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('budget_goals')
          .doc(goal.id)
          .set(goal.toMap());
    } catch (e) {
      print('Error adding budget goal: $e');
      rethrow;
    }
  }

  // Get all budget goals
  Stream<List<BudgetGoal>> getBudgetGoals() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('budget_goals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BudgetGoal.fromMap(doc.data()))
          .toList();
    });
  }

  // Update budget goal
  Future<void> updateBudgetGoal(BudgetGoal goal) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('budget_goals')
          .doc(goal.id)
          .update(goal.toMap());
    } catch (e) {
      print('Error updating budget goal: $e');
      rethrow;
    }
  }

  // Delete budget goal
  Future<void> deleteBudgetGoal(String goalId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('budget_goals')
          .doc(goalId)
          .delete();
    } catch (e) {
      print('Error deleting budget goal: $e');
      rethrow;
    }
  }

  // Get active budget goals (not completed and not expired)
  Future<List<BudgetGoal>> getActiveBudgetGoals() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('budget_goals')
          .where('endDate', isGreaterThanOrEqualTo: now.toIso8601String())
          .get();

      return snapshot.docs
          .map((doc) => BudgetGoal.fromMap(doc.data()))
          .where((goal) => !goal.isCompleted)
          .toList();
    } catch (e) {
      print('Error getting active budget goals: $e');
      return [];
    }
  }

  // Update expense limit goals automatically when expense is added
  Future<void> updateExpenseLimitGoals(Expense expense) async {
    try {
      print('🔄 Starting expense limit goal update for expense: ${expense.amount}');
      final activeGoals = await getActiveBudgetGoals();
      print('📊 Found ${activeGoals.length} active goals');
      
      if (activeGoals.isEmpty) {
        print('⚠️ No active goals found - this might be why goals aren\'t updating');
        return;
      }
      
      bool updatedAnyGoal = false;
      for (var goal in activeGoals) {
        print('🔍 Checking goal: ${goal.name}, category: ${goal.category}');
        if (goal.category == 'expense_limit') {
          // Only update goals that were created BEFORE or ON THE SAME DAY as the expense date
          // This prevents historical expenses from affecting new goals
          final goalDate = DateTime(goal.createdAt.year, goal.createdAt.month, goal.createdAt.day);
          final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
          
          if (goalDate.isBefore(expenseDate) || goalDate.isAtSameMomentAs(expenseDate)) {
            final oldAmount = goal.currentAmount;
            final newCurrentAmount = goal.currentAmount + expense.amount;
            
            print('📈 Updating goal: ${goal.name} from $oldAmount to $newCurrentAmount (+${expense.amount})');
            
            final updatedGoal = goal.copyWith(currentAmount: newCurrentAmount);
            await updateBudgetGoal(updatedGoal);
            updatedAnyGoal = true;
            
            print('✅ Successfully updated expense goal: ${goal.name}');
            
            // Check if we should show notification after update
            await _checkExpenseGoalNotification(updatedGoal);
          } else {
            print('⏭️ Skipping goal: ${goal.name} - goal created after expense date (${goal.createdAt} vs ${expense.date})');
          }
        } else {
          print('⏭️ Skipping goal: ${goal.name} (category: ${goal.category}) - not an expense_limit goal');
        }
      }
      
      if (updatedAnyGoal) {
        print('🎉 Successfully updated expense limit goals');
      } else {
        print('ℹ️ No expense limit goals were updated');
      }
    } catch (e) {
      print('❌ Error updating expense limit goals: $e');
      print('❌ Stack trace: ${e.toString()}');
    }
  }

  // Update expense limit goals when expense is deleted (subtract amount)
  Future<void> _updateExpenseLimitGoalsOnDelete(Expense expense) async {
    try {
      print('🔄 Starting expense limit goal update for deleted expense: ${expense.amount}');
      final activeGoals = await getActiveBudgetGoals();
      print('📊 Found ${activeGoals.length} active goals');
      
      if (activeGoals.isEmpty) {
        print('⚠️ No active goals found - this might be why goals aren\'t updating');
        return;
      }
      
      bool updatedAnyGoal = false;
      for (var goal in activeGoals) {
        print('🔍 Checking goal: ${goal.name}, category: ${goal.category}');
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
            
            print('📉 Updating goal: ${goal.name} from $oldAmount to $finalAmount (-${expense.amount})');
            
            final updatedGoal = goal.copyWith(currentAmount: finalAmount);
            await updateBudgetGoal(updatedGoal);
            updatedAnyGoal = true;
            
            print('✅ Successfully updated expense goal: ${goal.name}');
            
            // Check if we should show notification after update
            await _checkExpenseGoalNotification(updatedGoal);
          } else {
            print('⏭️ Skipping goal: ${goal.name} - goal created after expense date (${goal.createdAt} vs ${expense.date})');
          }
        } else {
          print('⏭️ Skipping goal: ${goal.name} (category: ${goal.category}) - not an expense_limit goal');
        }
      }
      
      if (updatedAnyGoal) {
        print('🎉 Successfully updated expense limit goals after deletion');
      } else {
        print('ℹ️ No expense limit goals were updated');
      }
    } catch (e) {
      print('❌ Error updating expense limit goals on delete: $e');
      print('❌ Stack trace: ${e.toString()}');
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
    } catch (e) {
      print('Error checking expense goal notification: $e');
    }
  }

  // ==================== AUTH OPERATIONS ====================

  // Sign in anonymously (for now, we'll add proper auth later)
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
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

  Future<MonthlyBudget?> getMonthlyBudget(int year, int month) async {
    return await budgetService.getMonthlyBudget(year, month);
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