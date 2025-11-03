import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income_source.dart';
import '../models/expense.dart';
import '../services/firebase_service.dart';
import '../services/date_helper.dart';
import '../services/income_calculator.dart';
import '../widgets/date_filter_widget.dart';
import '../widgets/swipeable_expense_tile.dart';
import '../widgets/enhanced_balance_card.dart';
import '../widgets/budget_tracking_card.dart';
import 'income_tracker_screen.dart';
import 'add_expense_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'budget_goals_screen.dart';

// Modern Gradient Color System
class AppColors {
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFEF4444);
  static const Color neutral = Color(0xFFF59E0B);
  static const Color gradientStart = Color(0xFF667EEA);
  static const Color gradientEnd = Color(0xFF764BA2);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color background = Color(0xFFF9FAFB);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF3F4F6);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;
  late PageController _pageController;

  final List<Widget> _screens = [
    const DashboardTab(),
    const AnalyticsScreen(),
    const IncomeTrackerScreen(),
    const BudgetGoalsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    if (index == 0) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: _buildModernBottomNav(),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientStart.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const AddExpenseScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            foregroundColor: Colors.white, 
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.bar_chart_rounded, 'Stats'),
              _buildNavItem(2, Icons.account_balance_wallet_rounded, 'Income'),
              _buildNavItem(3, Icons.flag_rounded, 'Goals'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Reusable Header Widget
class CommonAppBar extends StatelessWidget {
  final String title;
  final String subtitle;

  const CommonAppBar({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gradientStart.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
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
        child: StreamBuilder<List<IncomeSource>>(
          stream: firebaseService.getIncomeSources(),
          builder: (context, incomeSnapshot) {
            return StreamBuilder<List<Expense>>(
              stream: firebaseService.getExpenses(
                startDate: _currentFilter.startDate,
                endDate: _currentFilter.endDate,
              ),
              builder: (context, expenseSnapshot) {
                if (incomeSnapshot.connectionState == ConnectionState.waiting ||
                    expenseSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeletonLoader();
                }

                final incomeSources = incomeSnapshot.data ?? [];
                double monthlyIncome = IncomeCalculator.calculateIncomeForPeriod(
                  incomeSources,
                  _currentFilter,
                );

                double monthlyExpenses = 0;
                if (expenseSnapshot.hasData) {
                  for (var expense in expenseSnapshot.data!) {
                    monthlyExpenses += expense.amount;
                  }
                }

                final remaining = monthlyIncome - monthlyExpenses;
                final expenses = expenseSnapshot.data ?? [];

                // Calculate category spending for budget tracking
                Map<String, double> categorySpent = {};
                for (var expense in expenses) {
                  categorySpent[expense.category] = 
                      (categorySpent[expense.category] ?? 0) + expense.amount;
                }

                return FutureBuilder<Map<String, dynamic>>(
                  future: firebaseService.getCurrentMonthBalanceWithCarryover(
                    incomeSources: incomeSources,
                    expenses: expenses,
                    year: _currentFilter.year,
                    month: _currentFilter.month,
                  ),
                  builder: (context, balanceSnapshot) {
                    final balanceData = balanceSnapshot.data ?? {};
                    final carryover = balanceData['carryoverFromPrevious'] ?? 0.0;
                    final totalSavings = balanceData['totalSavings'] ?? 0.0;
                    final hasDebt = balanceData['hasDebt'] ?? false;
                    final debtAmount = balanceData['debtAmount'] ?? 0.0;

                    return FutureBuilder(
                      future: firebaseService.getMonthlyBudget(
                        _currentFilter.year,
                        _currentFilter.month,
                      ),
                      builder: (context, budgetSnapshot) {
                        final budget = budgetSnapshot.data;
                        final hasBudget = budget != null;

                        return RefreshIndicator(
                          onRefresh: () async {
                            await Future.delayed(const Duration(seconds: 1));
                          },
                          color: AppColors.gradientStart,
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: CommonAppBar(
                                  title: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                                  subtitle: _getGreeting(),
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
                                  child: EnhancedBalanceCard(
                                    remainingBalance: remaining,
                                    carryoverFromPrevious: carryover,
                                    totalSavings: totalSavings,
                                    monthlyIncome: monthlyIncome,
                                    monthlyExpenses: monthlyExpenses,
                                    hasDebt: hasDebt,
                                    debtAmount: debtAmount,
                                    filter: _currentFilter,
                                    noIncomeSources: incomeSources.isEmpty,
                                  ),
                                ),
                              ),

                              const SliverToBoxAdapter(child: SizedBox(height: 24)),

                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: BudgetTrackingCard(
                                    budget: budget,
                                    categorySpent: categorySpent,
                                    hasBudget: hasBudget,
                                    currentFilter: _currentFilter,
                                  ),
                                ),
                              ),

                              const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildQuickStatCard(
                                  _currentFilter.isCurrentMonth ? 'Income' : 'Income',
                                  DateHelper.formatCurrency(monthlyIncome),
                                  Icons.trending_up_rounded,
                                  AppColors.income,
                                  subtitle: monthlyIncome == 0 && incomeSources.isEmpty
                                      ? 'No income sources'
                                      : monthlyIncome == 0 && incomeSources.isNotEmpty
                                          ? 'No income data'
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickStatCard(
                                  'Expenses',
                                  DateHelper.formatCurrency(monthlyExpenses),
                                  Icons.trending_down_rounded,
                                  AppColors.expense,
                                  subtitle: monthlyExpenses == 0 ? 'No expenses' : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 32)),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Transactions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'See All',
                                  style: TextStyle(
                                    color: AppColors.gradientStart,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 12)),

                      if (expenses.isEmpty)
                        SliverToBoxAdapter(
                          child: _buildEmptyTransactions(_currentFilter.displayText),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final expense = expenses[index];
                                return SwipeableExpenseTile(
                                  key: ValueKey(expense.id),
                                  expense: expense,
                                  onExpenseUpdated: () {
                                    // Trigger a rebuild to refresh the expense list
                                    setState(() {});
                                  },
                                );
                              },
                              childCount: expenses.length > 5 ? 5 : expenses.length,
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernBalanceCard(
    double remaining, 
    double income, 
    double expenses,
    DateFilter filter,
    bool noIncomeSources,
  ) {
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
            colors: remaining >= 0
                ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                : [const Color(0xFFEF4444), const Color(0xFFF87171)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: (remaining >= 0 ? AppColors.income : AppColors.expense).withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  filter.isCurrentMonth ? 'Total Balance' : 'Balance',
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
            ),
            const SizedBox(height: 12),
            Text(
              DateHelper.formatCurrency(remaining),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            if (noIncomeSources && income == 0) ...[
              const SizedBox(height: 8),
              const Text(
                'Add income source to track earnings',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ] else if (!filter.isCurrentMonth && income == 0) ...[
              const SizedBox(height: 8),
              const Text(
                'No income data for this period',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(
    String label, 
    String value, 
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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildEmptyTransactions(String monthName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No expenses recorded in $monthName',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

}