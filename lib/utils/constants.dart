/// App-wide constants
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // Expense thresholds
  static const double largeExpenseThreshold = 100.0;
  static const double maxExpenseAmount = 1000000.0;
  static const double minExpenseAmount = 0.01;

  // Image settings
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int imageQuality = 85;

  // Date ranges
  static final DateTime appStartDate = DateTime(2020);
  static final DateTime appEndDate = DateTime(2100);

  // Budget thresholds
  static const double budgetWarningThreshold = 0.8; // 80%
  static const double budgetCriticalThreshold = 0.9; // 90%
  static const double budgetRecommendationBuffer = 1.2; // 20% buffer

  // Notification durations
  static const Duration shortNotificationDuration = Duration(seconds: 2);
  static const Duration mediumNotificationDuration = Duration(seconds: 3);
  static const Duration longNotificationDuration = Duration(seconds: 5);

  // Vibration
  static const int vibrationDuration = 100; // milliseconds

  // Pagination
  static const int expensesPerPage = 20;
  static const int recentExpensesLimit = 5;

  // Default values
  static const String defaultCategory = 'Food';
  static const List<String> expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Healthcare',
    'Other',
  ];

  // Date formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';

  // Currency
  static const String currencySymbol = '\$';
  static const int decimalPlaces = 2;

  // Firestore collections
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
  static const String incomeSourcesCollection = 'income_sources';
  static const String budgetsCollection = 'budgets';
  static const String budgetGoalsCollection = 'budget_goals';
  static const String monthlyBudgetsCollection = 'monthly_budgets';
  static const String monthlyBalancesCollection = 'monthly_balances';

  // Error messages
  static const String errorGeneric = 'An error occurred. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorInvalidInput = 'Invalid input. Please check your data.';
  static const String errorNotFound = 'Item not found.';
  static const String errorPermissionDenied = 'Permission denied.';

  // Success messages
  static const String successExpenseAdded = 'Expense added successfully!';
  static const String successExpenseUpdated = 'Expense updated successfully!';
  static const String successExpenseDeleted = 'Expense deleted successfully!';
  static const String successIncomeAdded = 'Income source added successfully!';
  static const String successBudgetSaved = 'Budget saved successfully!';
  static const String successGoalAdded = 'Goal added successfully!';

  // Validation messages
  static const String validationAmountRequired = 'Please enter an amount';
  static const String validationAmountInvalid = 'Please enter a valid number';
  static const String validationAmountPositive = 'Amount must be greater than 0';
  static const String validationAmountTooLarge = 'Amount is too large';
  static const String validationEmailRequired = 'Please enter your email';
  static const String validationEmailInvalid = 'Please enter a valid email';
  static const String validationPasswordRequired = 'Please enter your password';
  static const String validationPasswordTooShort = 'Password must be at least 6 characters';
  static const String validationNameRequired = 'Please enter your name';
}

/// App error codes
class AppErrorCodes {
  AppErrorCodes._();

  static const String networkError = 'NETWORK_ERROR';
  static const String authError = 'AUTH_ERROR';
  static const String validationError = 'VALIDATION_ERROR';
  static const String notFoundError = 'NOT_FOUND_ERROR';
  static const String permissionError = 'PERMISSION_ERROR';
  static const String unknownError = 'UNKNOWN_ERROR';
}

