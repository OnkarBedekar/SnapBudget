import '../models/income_source.dart';
import '../widgets/date_filter_widget.dart';

class IncomeCalculator {
  /// Calculate income for a specific month/year based on pay dates
  static double calculateIncomeForPeriod(
    List<IncomeSource> incomeSources,
    DateFilter filter,
  ) {
    double totalIncome = 0;

    for (var income in incomeSources) {
      // Check if the income source existed during the selected month
      //DateTime selectedMonthStart = DateTime(filter.year, filter.month, 1);
      DateTime selectedMonthEnd = DateTime(filter.year, filter.month + 1, 0, 23, 59, 59);
      
      // If the income source was created after the selected month ended, skip it
      if (income.createdAt.isAfter(selectedMonthEnd)) {
        continue;
      }
      
      // Count how many paydays occurred in the selected month
      int paydaysInMonth = _countPaydaysInMonth(
        income.payDates,
        filter.month,
        filter.year,
      );

      // If it's the current month and we're tracking hours, use earned so far
      if (filter.isCurrentMonth) {
        // For current month, use earned amount if hours are logged, otherwise show projected
        if (income.hoursWorked > 0) {
          totalIncome += income.earnedSoFar;
        } else {
          // Show projected income if no hours logged yet
          totalIncome += income.projectedIncome;
        }
      } else {
        // For past months, only show income if there were actual paydays
        if (paydaysInMonth > 0) {
          // Calculate based on paydays and target income per period
          // This assumes full target hours were worked for each pay period
          totalIncome += (income.projectedIncome / income.payDates.length) * paydaysInMonth;
        }
        // If no paydays in that month, income is 0
      }
    }

    return totalIncome;
  }

  /// Calculate total income potential over time (for analytics)
  static double calculateTotalSavingsOverTime(
    List<IncomeSource> incomeSources,
    DateFilter filter,
  ) {
    double totalSavings = 0;
    final now = DateTime.now();
    
    // Calculate from when the income source was created until the selected month
    for (var income in incomeSources) {
      DateTime startDate = income.createdAt;
      DateTime endDate = filter.endDate.isAfter(now) ? now : filter.endDate;
      
      // Calculate total months between start and end
      int totalMonths = ((endDate.year - startDate.year) * 12) + (endDate.month - startDate.month);
      
      // Only count months where there were actual paydays
      for (int monthOffset = 0; monthOffset <= totalMonths; monthOffset++) {
        DateTime checkDate = DateTime(startDate.year, startDate.month + monthOffset, 1);
        
        // Handle year overflow
        if (checkDate.month > 12) {
          checkDate = DateTime(checkDate.year + 1, checkDate.month - 12, 1);
        }
        
        // For current month, always include full projected income
        // For past months, only include if paydays occurred
        if (checkDate.year == now.year && checkDate.month == now.month) {
          // Current month: include full projected income
          totalSavings += income.projectedIncome;
        } else {
          // Past months: only include if paydays occurred
          int paydaysInMonth = _countPaydaysInMonth(income.payDates, checkDate.month, checkDate.year);
          if (paydaysInMonth > 0) {
            // Calculate income for this month based on paydays
            double monthlyIncome = (income.projectedIncome / income.payDates.length) * paydaysInMonth;
            totalSavings += monthlyIncome;
          }
        }
      }
    }
    
    return totalSavings;
  }

  /// Count how many pay dates occurred in a specific month
  static int _countPaydaysInMonth(List<int> payDates, int month, int year) {
    int count = 0;
    final now = DateTime.now();
    
    for (int payDate in payDates) {
      // Check if this pay date is valid for the given month
      try {
        final payDateTime = DateTime(year, month, payDate);
        
        // Only count if the payday actually occurred (is not in the future)
        if (payDateTime.isBefore(now) || _isSameDay(payDateTime, now)) {
          count++;
        }
      } catch (e) {
        // Invalid date (e.g., Feb 30), skip it
        continue;
      }
    }
    
    return count;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get display text for income explanation
  static String getIncomeExplanation(
    List<IncomeSource> incomeSources,
    DateFilter filter,
  ) {
    if (filter.isCurrentMonth) {
      // Check if any income source has logged hours
      bool hasLoggedHours = incomeSources.any((income) => income.hoursWorked > 0);
      return hasLoggedHours ? 'Earned this month' : 'Projected income';
    } else {
      int totalPaydays = 0;
      for (var income in incomeSources) {
        totalPaydays += _countPaydaysInMonth(
          income.payDates,
          filter.month,
          filter.year,
        );
      }
      return totalPaydays > 0 
          ? 'Income from $totalPaydays payday${totalPaydays == 1 ? '' : 's'}'
          : 'No income data for this month';
    }
  }
}