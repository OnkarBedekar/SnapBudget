import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/date_helper.dart';
import '../screens/home_screen.dart';

class SpendingInsights extends StatelessWidget {
  final List<Expense> currentMonthExpenses;
  final List<Expense> lastMonthExpenses;

  const SpendingInsights({
    Key? key,
    required this.currentMonthExpenses,
    required this.lastMonthExpenses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();

    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.gradientStart, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => _buildInsightItem(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> insight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: insight['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight['icon'],
              color: insight['color'],
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight['message'],
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateInsights() {
    List<Map<String, dynamic>> insights = [];

    // Calculate totals
    double currentTotal = currentMonthExpenses.fold(0, (sum, e) => sum + e.amount);
    double lastTotal = lastMonthExpenses.fold(0, (sum, e) => sum + e.amount);

    // Comparison with last month
    if (lastTotal > 0) {
      double changePercent = ((currentTotal - lastTotal) / lastTotal) * 100;
      
      if (changePercent > 20) {
        insights.add({
          'icon': Icons.trending_up,
          'color': AppColors.expense,
          'message': 'You\'re spending ${changePercent.toStringAsFixed(0)}% more than last month'
        });
      } else if (changePercent < -20) {
        insights.add({
          'icon': Icons.trending_down,
          'color': AppColors.income,
          'message': 'Great job! You\'re spending ${changePercent.abs().toStringAsFixed(0)}% less than last month'
        });
      }
    }

    // Category analysis
    Map<String, double> categoryTotals = {};
    for (var expense in currentMonthExpenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    if (categoryTotals.isNotEmpty) {
      var topCategory = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      double topPercent = (topCategory.value / currentTotal) * 100;
      
      if (topPercent > 40) {
        insights.add({
          'icon': Icons.pie_chart,
          'color': AppColors.neutral,
          'message': '${topCategory.key} is your biggest expense (${topPercent.toStringAsFixed(0)}%)'
        });
      }
    }

    // Daily average
    int daysInMonth = DateTime.now().day;
    if (daysInMonth > 0) {
      double dailyAverage = currentTotal / daysInMonth;
      insights.add({
        'icon': Icons.calendar_today,
        'color': AppColors.gradientEnd,
        'message': 'Your daily average spend: ${DateHelper.formatCurrency(dailyAverage)}'
      });
    }

    return insights;
  }
}