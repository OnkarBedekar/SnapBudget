class DateHelper {
  // Get the next payday based on pay dates (e.g., 7th and 22nd)
  static DateTime getNextPayday(List<int> payDates) {
    final now = DateTime.now();
    final currentDay = now.day;

    // Sort pay dates
    final sortedPayDates = List<int>.from(payDates)..sort();

    // Find next pay date this month
    for (int payDate in sortedPayDates) {
      if (payDate > currentDay) {
        return DateTime(now.year, now.month, payDate);
      }
    }

    // If no pay date left this month, get first pay date of next month
    if (sortedPayDates.isEmpty) {
      // If no pay dates, return a date far in the future
      return DateTime(now.year + 1, 1, 1);
    }
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    return DateTime(nextYear, nextMonth, sortedPayDates.first);
  }

  // Get days until next payday
  static int getDaysUntilPayday(List<int> payDates) {
    final nextPayday = getNextPayday(payDates);
    final now = DateTime.now();
    return nextPayday.difference(now).inDays;
  }

  // Get current pay period (from last payday to next payday)
  static DateRange getCurrentPayPeriod(List<int> payDates) {
    final now = DateTime.now();
    final nextPayday = getNextPayday(payDates);
    
    // Calculate previous payday
    DateTime? previousPayday;
    final sortedPayDates = List<int>.from(payDates)..sort();
    
    // Find the last pay date before today
    final reversedPayDates = sortedPayDates.reversed.toList();
    bool found = false;
    
    for (int payDate in reversedPayDates) {
      if (payDate <= now.day) {
        previousPayday = DateTime(now.year, now.month, payDate);
        found = true;
        break;
      }
    }
    
    if (!found) {
      // Previous payday was last month
      if (sortedPayDates.isEmpty) {
        // If no pay dates, use a date far in the past
        previousPayday = DateTime(now.year - 1, 1, 1);
      } else {
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
        previousPayday = DateTime(lastMonthYear, lastMonth, sortedPayDates.last);
      }
    }

    return DateRange(start: previousPayday ?? DateTime(now.year - 1, 1, 1), end: nextPayday);
  }

  // Format currency
  static String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Format date
  static String formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}