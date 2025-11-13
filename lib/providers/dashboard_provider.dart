import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/income_source.dart';
import '../models/expense.dart';
import '../models/monthly_budget.dart';
import '../services/firebase_service.dart';
import '../services/income_calculator.dart';
import '../widgets/date_filter_widget.dart';
import '../utils/logger.dart';

/// Provider for dashboard data management
/// Combines multiple streams and futures into a single state
class DashboardProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // State
  DateFilter _currentFilter = DateFilter.current();
  List<IncomeSource> _incomeSources = [];
  List<Expense> _expenses = [];
  Map<String, dynamic>? _balanceData;
  MonthlyBudget? _budget;
  
  // Computed values (cached)
  double? _monthlyIncome;
  double? _monthlyExpenses;
  double? _remainingBalance;
  Map<String, double>? _categorySpent;
  
  // Loading states
  bool _isLoadingIncome = true;
  bool _isLoadingExpenses = true;
  bool _isLoadingBalance = true;
  bool _isLoadingBudget = true;

  // Error states
  String? _incomeError;
  String? _expensesError;
  String? _balanceError;
  String? _budgetError;
  
  // Stream subscriptions
  StreamSubscription<List<IncomeSource>>? _incomeSubscription;
  StreamSubscription<List<Expense>>? _expensesSubscription;

  // Getters
  DateFilter get currentFilter => _currentFilter;
  List<IncomeSource> get incomeSources => _incomeSources;
  List<Expense> get expenses => _expenses;
  Map<String, dynamic>? get balanceData => _balanceData;
  MonthlyBudget? get budget => _budget;
  
  bool get isLoading => _isLoadingIncome || _isLoadingExpenses || _isLoadingBalance || _isLoadingBudget;
  bool get hasError => _incomeError != null || _expensesError != null || _balanceError != null || _budgetError != null;
  
  double get monthlyIncome {
    if (_monthlyIncome != null) return _monthlyIncome!;
    _monthlyIncome = IncomeCalculator.calculateIncomeForPeriod(
      _incomeSources,
      _currentFilter,
    );
    return _monthlyIncome!;
  }
  
  double get monthlyExpenses {
    if (_monthlyExpenses != null) return _monthlyExpenses!;
    double total = 0.0;
    for (var expense in _expenses) {
      total += expense.amount;
    }
    _monthlyExpenses = total;
    return total;
  }
  
  double get remainingBalance {
    if (_remainingBalance != null) return _remainingBalance!;
    final balance = monthlyIncome - monthlyExpenses;
    _remainingBalance = balance;
    return balance;
  }
  
  Map<String, double> get categorySpent {
    if (_categorySpent != null) return _categorySpent!;
    _categorySpent = {};
    for (var expense in _expenses) {
      _categorySpent![expense.category] = 
          (_categorySpent![expense.category] ?? 0) + expense.amount;
    }
    return _categorySpent!;
  }
  
  double get carryoverFromPrevious => _balanceData?['carryoverFromPrevious'] ?? 0.0;
  double get totalSavings => _balanceData?['totalSavings'] ?? 0.0;
  bool get hasDebt => _balanceData?['hasDebt'] ?? false;
  double get debtAmount => _balanceData?['debtAmount'] ?? 0.0;
  bool get hasBudget => _budget != null;

  DashboardProvider() {
    _initialize();
  }

  /// Initialize streams and load data
  void _initialize() {
    _loadIncomeSources();
    _loadExpenses();
    _loadBalanceData();
    _loadBudget();
  }

  /// Load income sources stream
  void _loadIncomeSources() {
    _isLoadingIncome = true;
    _incomeError = null;
    notifyListeners();

    // Cancel existing subscription
    _incomeSubscription?.cancel();
    
    _incomeSubscription = _firebaseService.getIncomeSources().listen(
      (incomeSources) {
        _incomeSources = incomeSources;
        _isLoadingIncome = false;
        _invalidateComputedValues();
        // Reload balance data when income sources change
        _loadBalanceData();
        notifyListeners();
        AppLogger.d('Income sources loaded: ${incomeSources.length}');
      },
      onError: (error) {
        _isLoadingIncome = false;
        _incomeError = error.toString();
        AppLogger.e('Error loading income sources', error);
        notifyListeners();
      },
    );
  }

  /// Load expenses stream
  void _loadExpenses() {
    _isLoadingExpenses = true;
    _expensesError = null;
    notifyListeners();

    // Cancel existing subscription
    _expensesSubscription?.cancel();
    
      _expensesSubscription = _firebaseService.getExpenses(
        startDate: _currentFilter.startDate,
        endDate: _currentFilter.endDate,
      ).listen(
      (expenses) {
        _expenses = expenses;
        _isLoadingExpenses = false;
        _invalidateComputedValues();
        // Reload balance data when expenses change (only if we have income sources)
        if (_incomeSources.isNotEmpty) {
          _loadBalanceData();
        }
        // Reload budget when expenses change
        _loadBudget();
        notifyListeners();
        AppLogger.d('Expenses loaded: ${expenses.length}');
      },
      onError: (error) {
        _isLoadingExpenses = false;
        _expensesError = error.toString();
        AppLogger.e('Error loading expenses', error);
        notifyListeners();
      },
    );
  }

  /// Load balance data
  Future<void> _loadBalanceData() async {
    // Don't reload if we don't have income sources or expenses yet
    // This prevents unnecessary API calls and errors
    if (_isLoadingIncome || _isLoadingExpenses) {
      return;
    }

    _isLoadingBalance = true;
    _balanceError = null;
    notifyListeners();

    try {
      final balanceData = await _firebaseService.getCurrentMonthBalanceWithCarryover(
        incomeSources: _incomeSources,
        expenses: _expenses,
        year: _currentFilter.year,
        month: _currentFilter.month,
      );
      _balanceData = balanceData;
      _isLoadingBalance = false;
      notifyListeners();
      AppLogger.d('Balance data loaded');
    } catch (e, stackTrace) {
      _isLoadingBalance = false;
      _balanceError = e.toString();
      AppLogger.e('Error loading balance data', e, stackTrace);
      notifyListeners();
    }
  }

  /// Load budget data
  Future<void> _loadBudget() async {
    _isLoadingBudget = true;
    _budgetError = null;
    notifyListeners();

    try {
      final budget = await _firebaseService.getMonthlyBudget(
        _currentFilter.year,
        _currentFilter.month,
      );
      _budget = budget;
      _isLoadingBudget = false;
      notifyListeners();
      AppLogger.d('Budget loaded: ${budget != null}');
    } catch (e, stackTrace) {
      _isLoadingBudget = false;
      _budgetError = e.toString();
      AppLogger.e('Error loading budget', e, stackTrace);
      notifyListeners();
    }
  }

  /// Update filter and reload data
  void updateFilter(DateFilter filter) {
    if (_currentFilter.year == filter.year && 
        _currentFilter.month == filter.month) {
      return; // No change
    }
    
    _currentFilter = filter;
    _invalidateComputedValues();
    _loadExpenses(); // Reload expenses for new date range
    _loadBalanceData(); // Reload balance for new month
    _loadBudget(); // Reload budget for new month
    notifyListeners();
    AppLogger.i('Filter updated: ${filter.displayText}');
  }

  /// Refresh all data
  Future<void> refresh() async {
    AppLogger.i('Refreshing dashboard data');
    _invalidateComputedValues();
    _loadIncomeSources();
    _loadExpenses();
    await Future.wait([
      _loadBalanceData(),
      _loadBudget(),
    ]);
  }

  /// Invalidate computed values to force recalculation
  void _invalidateComputedValues() {
    _monthlyIncome = null;
    _monthlyExpenses = null;
    _remainingBalance = null;
    _categorySpent = null;
  }

  /// Get recent expenses (limited)
  List<Expense> getRecentExpenses({int limit = 5}) {
    return _expenses.take(limit).toList();
  }

  @override
  void dispose() {
    AppLogger.d('DashboardProvider disposed');
    _incomeSubscription?.cancel();
    _expensesSubscription?.cancel();
    super.dispose();
  }
}

