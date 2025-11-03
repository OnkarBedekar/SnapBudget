import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/monthly_balance.dart';
import '../models/income_source.dart';
import '../models/expense.dart';
import 'income_calculator.dart';

class MonthlyBalanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Save or update monthly balance with carryover logic
  Future<void> saveMonthlyBalance({
    required int year,
    required int month,
    required double income,
    required double expenses,
    required double actualHoursWorked,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final now = DateTime.now();
      final balanceId = '${year}_${month.toString().padLeft(2, '0')}';
      
      // Get previous month's balance for carryover
      final previousBalance = await _getPreviousMonthBalance(year, month);
      
      // Calculate carryover from previous month
      double carryoverFromPrevious = 0;
      double totalSavings = 0;
      
      if (previousBalance != null) {
        carryoverFromPrevious = previousBalance.remainingBalance;
        totalSavings = previousBalance.totalSavings;
      }

      final netBalance = income - expenses;
      
      // Calculate new total savings (only add positive balances)
      if (netBalance > 0) {
        totalSavings += netBalance;
      }

      final monthlyBalance = MonthlyBalance(
        id: balanceId,
        userId: userId,
        year: year,
        month: month,
        income: income,
        expenses: expenses,
        netBalance: netBalance,
        carryoverFromPrevious: carryoverFromPrevious,
        totalSavings: totalSavings,
        actualHoursWorked: actualHoursWorked,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('monthly_balances')
          .doc(balanceId)
          .set(monthlyBalance.toMap());
          
    } catch (e) {
      print('Error saving monthly balance: $e');
      rethrow;
    }
  }

  /// Get monthly balance for a specific month
  Future<MonthlyBalance?> getMonthlyBalance(int year, int month) async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final balanceId = '${year}_${month.toString().padLeft(2, '0')}';
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('monthly_balances')
          .doc(balanceId)
          .get();

      if (doc.exists) {
        return MonthlyBalance.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting monthly balance: $e');
      return null;
    }
  }

  /// Get all monthly balances (for analytics)
  Stream<List<MonthlyBalance>> getMonthlyBalances() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('monthly_balances')
        .orderBy('year')
        .orderBy('month')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MonthlyBalance.fromMap(doc.data()))
          .toList();
    });
  }

  /// Calculate current month balance with carryover
  Future<Map<String, dynamic>> getCurrentMonthBalanceWithCarryover({
    required List<IncomeSource> incomeSources,
    required List<Expense> expenses,
    required int year,
    required int month,
  }) async {
    // Calculate income and expenses for current month
    final monthlyIncome = IncomeCalculator.calculateIncomeForPeriod(
      incomeSources,
      _createDateFilter(year, month),
    );

    final monthlyExpenses = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    
    // Calculate actual hours worked this month
    final actualHoursWorked = incomeSources.fold(0.0, (sum, source) => sum + source.hoursWorked);

    // Get previous month's balance for carryover
    final previousBalance = await _getPreviousMonthBalance(year, month);
    final carryoverFromPrevious = previousBalance?.remainingBalance ?? 0;
    final previousTotalSavings = previousBalance?.totalSavings ?? 0;

    final netBalance = monthlyIncome - monthlyExpenses;
    final totalSavings = previousTotalSavings + (netBalance > 0 ? netBalance : 0);
    final remainingBalance = carryoverFromPrevious + netBalance;

    return {
      'income': monthlyIncome,
      'expenses': monthlyExpenses,
      'netBalance': netBalance,
      'carryoverFromPrevious': carryoverFromPrevious,
      'remainingBalance': remainingBalance,
      'totalSavings': totalSavings,
      'actualHoursWorked': actualHoursWorked,
      'hasDebt': remainingBalance < 0,
      'debtAmount': remainingBalance < 0 ? remainingBalance.abs() : 0,
    };
  }

  /// Update actual hours worked for a specific month
  Future<void> updateActualHoursWorked(int year, int month, double hoursWorked) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final balanceId = '${year}_${month.toString().padLeft(2, '0')}';
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('monthly_balances')
          .doc(balanceId)
          .update({
        'actualHoursWorked': hoursWorked,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating actual hours worked: $e');
      rethrow;
    }
  }

  /// Get month-over-month comparison data
  Future<Map<String, dynamic>> getMonthOverMonthComparison(int year, int month) async {
    final currentMonth = await getMonthlyBalance(year, month);
    final previousMonth = await _getPreviousMonthBalance(year, month);

    if (currentMonth == null && previousMonth == null) {
      return {
        'hasData': false,
        'currentBalance': 0,
        'previousBalance': 0,
        'change': 0,
        'changePercent': 0,
        'trend': 'no_data',
      };
    }

    final currentBalance = currentMonth?.remainingBalance ?? 0;
    final previousBalance = previousMonth?.remainingBalance ?? 0;
    
    double change = currentBalance - previousBalance;
    double changePercent = previousBalance != 0 ? (change / previousBalance.abs()) * 100 : 0;
    
    String trend = 'stable';
    if (change > 0) {
      trend = 'improving';
    } else if (change < 0) {
      trend = 'declining';
    }

    return {
      'hasData': true,
      'currentBalance': currentBalance,
      'previousBalance': previousBalance,
      'change': change,
      'changePercent': changePercent,
      'trend': trend,
    };
  }

  /// Private helper methods
  Future<MonthlyBalance?> _getPreviousMonthBalance(int year, int month) async {
    int prevMonth = month - 1;
    int prevYear = year;
    
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear = year - 1;
    }
    
    return await getMonthlyBalance(prevYear, prevMonth);
  }

  dynamic _createDateFilter(int year, int month) {
    // Create a simple date filter object for the income calculator
    return _DateFilter(year: year, month: month);
  }
}

// Simple date filter class for internal use
class _DateFilter {
  final int year;
  final int month;

  _DateFilter({required this.year, required this.month});

  DateTime get startDate => DateTime(year, month, 1);
  DateTime get endDate => DateTime(year, month + 1, 0, 23, 59, 59);
  bool get isCurrentMonth {
    final now = DateTime.now();
    return month == now.month && year == now.year;
  }
}
