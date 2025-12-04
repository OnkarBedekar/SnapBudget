import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/date_helper.dart';
import '../widgets/date_filter_widget.dart';
import '../widgets/swipeable_expense_tile.dart';
import '../widgets/enhanced_balance_card.dart';
import '../widgets/budget_tracking_card.dart';
import '../providers/dashboard_provider.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            // Show loading state only if we're actually loading AND have no data yet
            // For new users with empty data, we should show the dashboard, not skeleton
            if (provider.isLoading && 
                provider.incomeSources.isEmpty && 
                provider.expenses.isEmpty &&
                !provider.hasError) {
              return _buildSkeletonLoader();
            }

            final expenses = provider.expenses;
            final recentExpenses = provider.getRecentExpenses(limit: 5);

            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
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
                      currentFilter: provider.currentFilter,
                      onFilterChanged: (filter) {
                        provider.updateFilter(filter);
                      },
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: EnhancedBalanceCard(
                        remainingBalance: provider.remainingBalance,
                        carryoverFromPrevious: provider.carryoverFromPrevious,
                        totalSavings: provider.totalSavings,
                        monthlyIncome: provider.monthlyIncome,
                        monthlyExpenses: provider.monthlyExpenses,
                        hasDebt: provider.hasDebt,
                        debtAmount: provider.debtAmount,
                        filter: provider.currentFilter,
                        noIncomeSources: provider.incomeSources.isEmpty,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: BudgetTrackingCard(
                        budget: provider.budget,
                        categorySpent: provider.categorySpent,
                        hasBudget: provider.hasBudget,
                        currentFilter: provider.currentFilter,
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
                              provider.currentFilter.isCurrentMonth ? 'Income' : 'Income',
                              DateHelper.formatCurrency(provider.monthlyIncome),
                              Icons.trending_up_rounded,
                              AppColors.income,
                              subtitle: provider.monthlyIncome == 0 && provider.incomeSources.isEmpty
                                  ? 'No income sources'
                                  : provider.monthlyIncome == 0 && provider.incomeSources.isNotEmpty
                                      ? 'No income data'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickStatCard(
                              'Expenses',
                              DateHelper.formatCurrency(provider.monthlyExpenses),
                              Icons.trending_down_rounded,
                              AppColors.expense,
                              subtitle: provider.monthlyExpenses == 0 ? 'No expenses' : null,
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
                      child: _buildEmptyTransactions(provider.currentFilter.displayText),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final expense = recentExpenses[index];
                            return SwipeableExpenseTile(
                              key: ValueKey(expense.id),
                              expense: expense,
                              onExpenseUpdated: () {
                                // Refresh provider data
                                provider.refresh();
                              },
                            );
                          },
                          childCount: recentExpenses.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
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