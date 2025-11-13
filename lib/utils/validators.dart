import 'constants.dart';

/// Input validation utilities
class Validators {
  Validators._(); // Private constructor

  /// Validate email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.validationEmailRequired;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return AppConstants.validationEmailInvalid;
    }

    return null;
  }

  /// Validate password
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return AppConstants.validationPasswordRequired;
    }

    if (value.length < minLength) {
      return AppConstants.validationPasswordTooShort;
    }

    return null;
  }

  /// Validate name
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.validationNameRequired;
    }

    if (value.trim().isEmpty) {
      return AppConstants.validationNameRequired;
    }

    return null;
  }

  /// Validate amount
  static String? amount(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.validationAmountRequired;
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return AppConstants.validationAmountInvalid;
    }

    if (amount <= 0) {
      return AppConstants.validationAmountPositive;
    }

    if (amount > AppConstants.maxExpenseAmount) {
      return AppConstants.validationAmountTooLarge;
    }

    return null;
  }

  /// Validate required field
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validate date is not in future
  static String? dateNotInFuture(DateTime? value) {
    if (value == null) {
      return 'Please select a date';
    }

    if (value.isAfter(DateTime.now())) {
      return 'Date cannot be in the future';
    }

    return null;
  }

  /// Validate date range
  static String? dateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return 'Please select both start and end dates';
    }

    if (start.isAfter(end)) {
      return 'Start date must be before end date';
    }

    return null;
  }

  /// Validate category
  static String? category(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a category';
    }

    if (!AppConstants.expenseCategories.contains(value)) {
      return 'Invalid category';
    }

    return null;
  }

  /// Combine multiple validators
  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}

