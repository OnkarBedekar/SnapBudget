import 'package:flutter/material.dart';
import '../services/date_helper.dart';
import '../screens/home_screen.dart';

class MonthOverMonthCard extends StatelessWidget {
  final Map<String, dynamic> comparisonData;
  final String currentMonth;
  final String previousMonth;

  const MonthOverMonthCard({
    Key? key,
    required this.comparisonData,
    required this.currentMonth,
    required this.previousMonth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasData = comparisonData['hasData'] as bool? ?? false;
    
    if (!hasData) {
      return _buildNoDataCard();
    }

    final currentBalance = comparisonData['currentBalance'] as double? ?? 0;
    final previousBalance = comparisonData['previousBalance'] as double? ?? 0;
    final change = comparisonData['change'] as double? ?? 0;
    final changePercent = comparisonData['changePercent'] as double? ?? 0;
    final trend = comparisonData['trend'] as String? ?? 'stable';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getTrendColors(trend),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getTrendColor(trend).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(trend),
          const SizedBox(height: 16),
          _buildComparison(currentBalance, previousBalance),
          const SizedBox(height: 16),
          _buildChangeIndicator(change, changePercent, trend),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neutral.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.timeline,
              color: AppColors.neutral,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Comparison Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete at least 2 months of data to see trends.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String trend) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getTrendIcon(trend),
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Month-over-Month',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getTrendText(trend),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparison(double currentBalance, double previousBalance) {
    return Row(
      children: [
        Expanded(
          child: _buildBalanceColumn('This Month', currentBalance, currentMonth),
        ),
        Container(
          width: 1,
          height: 60,
          color: Colors.white.withOpacity(0.3),
        ),
        Expanded(
          child: _buildBalanceColumn('Last Month', previousBalance, previousMonth),
        ),
      ],
    );
  }

  Widget _buildBalanceColumn(String label, double balance, String month) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          month,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DateHelper.formatCurrency(balance),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChangeIndicator(double change, double changePercent, String trend) {
    final isPositive = change > 0;
    final isNegative = change < 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPositive ? Icons.trending_up : isNegative ? Icons.trending_down : Icons.horizontal_rule,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isPositive 
                ? '+${DateHelper.formatCurrency(change)} (+${changePercent.toStringAsFixed(1)}%)'
                : isNegative
                    ? '${DateHelper.formatCurrency(change)} (${changePercent.toStringAsFixed(1)}%)'
                    : 'No change',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getTrendColors(String trend) {
    switch (trend) {
      case 'improving':
        return [const Color(0xFF10B981), const Color(0xFF34D399)];
      case 'declining':
        return [const Color(0xFFEF4444), const Color(0xFFF87171)];
      default:
        return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return AppColors.income;
      case 'declining':
        return AppColors.expense;
      default:
        return AppColors.neutral;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.timeline;
    }
  }

  String _getTrendText(String trend) {
    switch (trend) {
      case 'improving':
        return 'Your finances are improving';
      case 'declining':
        return 'Your finances need attention';
      default:
        return 'Your finances are stable';
    }
  }
}
