import 'package:flutter/material.dart';
import '../models/monthly_budget.dart';
import '../services/date_helper.dart';
import '../screens/home_screen.dart';
import '../screens/budget_setup_screen.dart';
import '../widgets/date_filter_widget.dart';

class BudgetTrackingCard extends StatelessWidget {
  final MonthlyBudget? budget;
  final Map<String, double> categorySpent;
  final bool hasBudget;
  final DateFilter? currentFilter;

  const BudgetTrackingCard({
    Key? key,
    this.budget,
    this.categorySpent = const {},
    this.hasBudget = false,
    this.currentFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!hasBudget || budget == null) {
      return _buildNoBudgetCard();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildOverallProgress(),
          const SizedBox(height: 16),
          _buildCategoryBreakdown(),
        ],
      ),
    );
  }

  Widget _buildNoBudgetCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.neutral.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.neutral,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No Budget Set',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Set a monthly budget to track your spending and stay on target.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final filter = currentFilter ?? DateFilter.current();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetSetupScreen(currentFilter: filter),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Set Budget'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.gradientStart,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly Budget',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${budget!.overallUtilization.toStringAsFixed(0)}% used',
                style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            budget!.overallStatus.displayName,
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverallProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateHelper.formatCurrency(budget!.actualSpent),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'of ${DateHelper.formatCurrency(budget!.totalBudget)}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: budget!.overallUtilization / 100,
            minHeight: 12,
            backgroundColor: AppColors.surfaceLight,
            color: _getStatusColor(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${budget!.overallUtilization.toStringAsFixed(1)}% utilized',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              DateHelper.formatCurrency(budget!.remainingBudget),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: budget!.remainingBudget >= 0 
                    ? AppColors.income 
                    : AppColors.expense,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    final categories = budget!.categoryBudgets.keys.toList();
    
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...categories.map((category) => _buildCategoryItem(category)),
      ],
    );
  }

  Widget _buildCategoryItem(String category) {
    final budgetAmount = budget!.categoryBudgets[category] ?? 0;
    final spentAmount = categorySpent[category] ?? 0;
    final remaining = budgetAmount - spentAmount;
    final utilization = budgetAmount > 0 ? (spentAmount / budgetAmount) * 100 : 0;
    final status = budget!.getCategoryStatus(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getCategoryStatusColor(status).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryStatusColor(status).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${utilization.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getCategoryStatusColor(status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateHelper.formatCurrency(spentAmount),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                DateHelper.formatCurrency(budgetAmount),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: utilization / 100,
              minHeight: 6,
              backgroundColor: AppColors.surfaceLight,
              color: _getCategoryStatusColor(status),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (budget!.overallStatus) {
      case BudgetStatus.good:
        return AppColors.income;
      case BudgetStatus.approaching:
        return AppColors.neutral;
      case BudgetStatus.warning:
        return const Color(0xFFFF9800);
      case BudgetStatus.overBudget:
        return AppColors.expense;
    }
  }

  IconData _getStatusIcon() {
    switch (budget!.overallStatus) {
      case BudgetStatus.good:
        return Icons.check_circle_outline;
      case BudgetStatus.approaching:
        return Icons.warning_amber_outlined;
      case BudgetStatus.warning:
        return Icons.warning_outlined;
      case BudgetStatus.overBudget:
        return Icons.error_outline;
    }
  }

  Color _getCategoryStatusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.good:
        return AppColors.income;
      case BudgetStatus.approaching:
        return AppColors.neutral;
      case BudgetStatus.warning:
        return const Color(0xFFFF9800);
      case BudgetStatus.overBudget:
        return AppColors.expense;
    }
  }
}
