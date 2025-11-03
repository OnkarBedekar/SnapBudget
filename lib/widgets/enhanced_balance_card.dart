import 'package:flutter/material.dart';
import '../models/income_source.dart';
import '../models/expense.dart';
import '../services/date_helper.dart';
import '../widgets/date_filter_widget.dart';
import '../screens/home_screen.dart';

class EnhancedBalanceCard extends StatelessWidget {
  final double remainingBalance;
  final double carryoverFromPrevious;
  final double totalSavings;
  final double monthlyIncome;
  final double monthlyExpenses;
  final bool hasDebt;
  final double debtAmount;
  final DateFilter filter;
  final bool noIncomeSources;

  const EnhancedBalanceCard({
    Key? key,
    required this.remainingBalance,
    required this.carryoverFromPrevious,
    required this.totalSavings,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.hasDebt,
    required this.debtAmount,
    required this.filter,
    required this.noIncomeSources,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getBalanceColors(),
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _getBalanceColor().withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildMainBalance(),
            const SizedBox(height: 16),
            _buildBreakdown(),
            if (hasDebt) ...[
              const SizedBox(height: 12),
              _buildDebtWarning(),
            ],
            if (carryoverFromPrevious != 0) ...[
              const SizedBox(height: 8),
              _buildCarryoverInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _getBalanceTitle(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            filter.displayText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainBalance() {
    return Text(
      DateHelper.formatCurrency(remainingBalance.abs()),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 42,
        fontWeight: FontWeight.bold,
        letterSpacing: -1,
      ),
    );
  }

  Widget _buildBreakdown() {
    return Column(
      children: [
        _buildBreakdownRow('Income', monthlyIncome, AppColors.income),
        const SizedBox(height: 8),
        _buildBreakdownRow('Expenses', monthlyExpenses, AppColors.expense),
        if (carryoverFromPrevious != 0) ...[
          const SizedBox(height: 8),
          _buildBreakdownRow(
            'From Last Month', 
            carryoverFromPrevious, 
            carryoverFromPrevious > 0 ? AppColors.income : AppColors.expense,
          ),
        ],
      ],
    );
  }

  Widget _buildBreakdownRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          DateHelper.formatCurrency(amount),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDebtWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re over budget by ${DateHelper.formatCurrency(debtAmount)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarryoverInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            carryoverFromPrevious > 0 ? Icons.trending_up : Icons.trending_down,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            carryoverFromPrevious > 0 
                ? 'Savings from previous month'
                : 'Debt from previous month',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getBalanceColors() {
    if (remainingBalance > 0) {
      return [const Color(0xFF10B981), const Color(0xFF34D399)];
    } else if (remainingBalance < 0) {
      return [const Color(0xFFEF4444), const Color(0xFFF87171)];
    } else {
      return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
    }
  }

  Color _getBalanceColor() {
    if (remainingBalance > 0) return AppColors.income;
    if (remainingBalance < 0) return AppColors.expense;
    return AppColors.neutral;
  }

  String _getBalanceTitle() {
    if (hasDebt) {
      return 'Over Budget';
    } else if (remainingBalance > 0) {
      return 'Available Balance';
    } else if (remainingBalance == 0) {
      return 'Break Even';
    } else {
      return 'Total Balance';
    }
  }
}
