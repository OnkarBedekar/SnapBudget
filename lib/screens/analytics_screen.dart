import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/income_source.dart';
import '../services/firebase_service.dart';
import '../services/date_helper.dart';
import '../services/income_calculator.dart';
import '../widgets/date_filter_widget.dart';
import '../widgets/month_over_month_card.dart';
import '../widgets/spending_insights.dart';
import 'home_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late DateFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = DateFilter.current();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<Expense>>(
          stream: firebaseService.getExpenses(
            startDate: _currentFilter.startDate,
            endDate: _currentFilter.endDate,
          ),
          builder: (context, expenseSnapshot) {
            return StreamBuilder<List<IncomeSource>>(
              stream: firebaseService.getIncomeSources(),
              builder: (context, incomeSnapshot) {
                if (expenseSnapshot.connectionState == ConnectionState.waiting ||
                    incomeSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gradientStart),
                  );
                }

                final expenses = expenseSnapshot.data ?? [];
                final incomeSources = incomeSnapshot.data ?? [];

                double totalIncome = IncomeCalculator.calculateIncomeForPeriod(
                  incomeSources,
                  _currentFilter,
                );

                double totalExpenses = 0;
                for (var expense in expenses) {
                  totalExpenses += expense.amount;
                }

                final netBalance = totalIncome - totalExpenses;

                Map<String, double> categoryTotals = {};
                for (var expense in expenses) {
                  categoryTotals[expense.category] =
                      (categoryTotals[expense.category] ?? 0) + expense.amount;
                }

                String incomeExplanation = IncomeCalculator.getIncomeExplanation(
                  incomeSources,
                  _currentFilter,
                );

                double totalSavingsOverTime = IncomeCalculator.calculateTotalSavingsOverTime(
                  incomeSources,
                  _currentFilter,
                );

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(
                      child: CommonAppBar(
                        title: 'Analytics',
                        subtitle: 'Financial Overview',
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: DateFilterWidget(
                        currentFilter: _currentFilter,
                        onFilterChanged: (filter) {
                          setState(() {
                            _currentFilter = filter;
                          });
                        },
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                totalIncome == 0 && !_currentFilter.isCurrentMonth
                                    ? 'Income (Estimated)'
                                    : _currentFilter.isCurrentMonth
                                        ? 'Income (Projected)'
                                        : 'Income',
                                DateHelper.formatCurrency(totalIncome),
                                Icons.arrow_downward_rounded,
                                AppColors.income,
                                subtitle: totalIncome > 0 ? incomeExplanation : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Expenses',
                                DateHelper.formatCurrency(totalExpenses),
                                Icons.arrow_upward_rounded,
                                AppColors.expense,
                                subtitle: expenses.isNotEmpty 
                                    ? '${expenses.length} transaction${expenses.length == 1 ? '' : 's'}'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildNetBalanceCard(netBalance, totalIncome, totalExpenses),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildTotalSavingsCard(totalSavingsOverTime, _currentFilter),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Month-over-month comparison
                    SliverToBoxAdapter(
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: firebaseService.getMonthOverMonthComparison(
                          _currentFilter.year,
                          _currentFilter.month,
                        ),
                        builder: (context, comparisonSnapshot) {
                          final comparisonData = comparisonSnapshot.data ?? {};
                          final prevMonth = _currentFilter.previousMonth();
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: MonthOverMonthCard(
                              comparisonData: comparisonData,
                              currentMonth: _currentFilter.displayText,
                              previousMonth: prevMonth.displayText,
                            ),
                          );
                        },
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Spending insights
                    SliverToBoxAdapter(
                      child: FutureBuilder<List<Expense>>(
                        future: () async {
                          final lastMonthFilter = _currentFilter.previousMonth();
                          final lastMonthExpenses = await firebaseService.getExpenses(
                            startDate: lastMonthFilter.startDate,
                            endDate: lastMonthFilter.endDate,
                          ).first;
                          return lastMonthExpenses;
                        }(),
                        builder: (context, lastMonthSnapshot) {
                          final lastMonthExpenses = lastMonthSnapshot.data ?? [];
                          return SpendingInsights(
                            currentMonthExpenses: expenses,
                            lastMonthExpenses: lastMonthExpenses,
                          );
                        },
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Spending by Category',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildCategoryBreakdown(categoryTotals, totalExpenses),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    if (categoryTotals.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Top Categories',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 12)),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildTopCategories(categoryTotals),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],

                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'All Transactions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildAllExpensesList(expenses),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label, 
    String amount, 
    IconData icon, 
    Color color,
    {String? subtitle}
  ) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNetBalanceCard(double netBalance, double income, double expenses) {
    Color balanceColor;
    IconData balanceIcon;
    String balanceLabel;

    if (netBalance > 0) {
      balanceColor = AppColors.income;
      balanceIcon = Icons.trending_up_rounded;
      balanceLabel = income > 0 ? 'Remaining Balance' : 'No Income Data';
    } else if (netBalance < 0) {
      balanceColor = AppColors.expense;
      balanceIcon = Icons.trending_down_rounded;
      balanceLabel = 'Over Budget';
    } else {
      if (income == 0 && expenses == 0) {
        balanceColor = AppColors.neutral;
        balanceIcon = Icons.info_outline;
        balanceLabel = 'No Data';
      } else {
        balanceColor = AppColors.neutral;
        balanceIcon = Icons.horizontal_rule_rounded;
        balanceLabel = 'Break Even';
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: netBalance > 0 && income > 0
              ? [const Color(0xFF10B981), const Color(0xFF34D399)]
              : netBalance < 0
                  ? [const Color(0xFFEF4444), const Color(0xFFF87171)]
                  : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: balanceColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balanceLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateHelper.formatCurrency(netBalance.abs()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (income == 0 && expenses > 0) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'No income recorded',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(balanceIcon, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  Widget _buildTotalSavingsCard(double totalSavings, DateFilter filter) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Income Potential',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateHelper.formatCurrency(totalSavings),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Since starting to track',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.trending_up_rounded, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(Map<String, double> categoryTotals, double total) {
    if (categoryTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No expenses in ${_currentFilter.displayText}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
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
        children: categoryTotals.entries.map((entry) {
          final percentage = total > 0 ? (entry.value / total) * 100 : 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(entry.key).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getCategoryIcon(entry.key),
                            color: _getCategoryColor(entry.key),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      DateHelper.formatCurrency(entry.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceLight,
                    color: AppColors.expense,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(1)}% of total',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopCategories(Map<String, double> categoryTotals) {
    var sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var topThree = sortedEntries.take(3).toList();

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: topThree.asMap().entries.map((entry) {
          int index = entry.key;
          var categoryEntry = entry.value;

          return Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getMedalColor(index).withOpacity(0.1),
                    ),
                  ),
                  Icon(
                    _getCategoryIcon(categoryEntry.key),
                    color: _getMedalColor(index),
                    size: 32,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                categoryEntry.key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateHelper.formatCurrency(categoryEntry.value),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getMedalColor(index),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAllExpensesList(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No expenses in ${_currentFilter.displayText}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: expenses.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getCategoryColor(expense.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(expense.category),
                color: _getCategoryColor(expense.category),
                size: 20,
              ),
            ),
            title: Text(
              expense.description ?? expense.category,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              DateHelper.formatDate(expense.date),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            trailing: Text(
              '- ${DateHelper.formatCurrency(expense.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.expense,
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'bills':
        return Icons.receipt_rounded;
      case 'healthcare':
        return Icons.medical_services_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF9800);
      case 'transport':
        return AppColors.accentBlue;
      case 'shopping':
        return AppColors.accentPink;
      case 'entertainment':
        return const Color(0xFFE91E63);
      case 'bills':
        return const Color(0xFF795548);
      case 'healthcare':
        return AppColors.expense;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textSecondary;
    }
  }
}