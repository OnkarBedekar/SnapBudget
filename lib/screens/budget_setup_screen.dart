import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../services/date_helper.dart';
import '../screens/home_screen.dart';
import '../widgets/date_filter_widget.dart';

class BudgetSetupScreen extends StatefulWidget {
  final DateFilter currentFilter;

  const BudgetSetupScreen({
    Key? key,
    required this.currentFilter,
  }) : super(key: key);

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  final _firebaseService = FirebaseService();
  final _totalBudgetController = TextEditingController();
  final _categoryControllers = <String, TextEditingController>{};
  
  bool _isLoading = false;
  final List<String> _categories = [
    'Food & Dining',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingBudget();
  }

  void _initializeControllers() {
    for (String category in _categories) {
      _categoryControllers[category] = TextEditingController();
    }
  }

  Future<void> _loadExistingBudget() async {
    try {
      final budget = await _firebaseService.getMonthlyBudget(
        widget.currentFilter.year,
        widget.currentFilter.month,
      );
      
      if (budget != null && mounted) {
        setState(() {
          _totalBudgetController.text = budget.totalBudget.toString();
          budget.categoryBudgets.forEach((category, amount) {
            if (_categoryControllers.containsKey(category)) {
              _categoryControllers[category]!.text = amount.toString();
            }
          });
        });
      }
    } catch (e, stackTrace) {
      // Error loading budget - will proceed with empty form
      // Logger would be used here if needed, but silently fail for UX
    }
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    for (var controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set Monthly Budget'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveBudget,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? AppColors.textSecondary : AppColors.gradientStart,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gradientStart))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildTotalBudgetSection(),
                  const SizedBox(height: 24),
                  _buildCategoryBudgetsSection(),
                  const SizedBox(height: 24),
                  _buildQuickSetupButtons(),
                  const SizedBox(height: 24),
                  _buildRecommendationsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Budget for ${widget.currentFilter.displayText}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Set spending limits to stay on track with your financial goals.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBudgetSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Monthly Budget',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _totalBudgetController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              hintText: 'Enter total budget amount',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gradientStart, width: 2),
              ),
            ),
            onChanged: (value) {
              _updateCategoryBudgetsFromTotal();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Budgets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set individual limits for each spending category.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ..._categories.map((category) => _buildCategoryInput(category)),
        ],
      ),
    );
  }

  Widget _buildCategoryInput(String category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextField(
              controller: _categoryControllers[category],
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                hintText: '0',
                prefixText: '\$',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.gradientStart, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSetupButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Setup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _applyQuickSetup('conservative'),
                  icon: const Icon(Icons.savings),
                  label: const Text('Conservative'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.income,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _applyQuickSetup('balanced'),
                  icon: const Icon(Icons.balance),
                  label: const Text('Balanced'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.neutral,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget Tips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const _BudgetTip(
            icon: Icons.rule,
            title: '50/30/20 Rule',
            description: 'Allocate 50% for needs, 30% for wants, 20% for savings.',
          ),
          const _BudgetTip(
            icon: Icons.track_changes,
            title: 'Track Regularly',
            description: 'Review your spending weekly to stay on track.',
          ),
          const _BudgetTip(
            icon: Icons.tune,
            title: 'Be Flexible',
            description: 'Adjust your budget based on your actual spending patterns.',
          ),
        ],
      ),
    );
  }

  void _updateCategoryBudgetsFromTotal() {
    final totalBudget = double.tryParse(_totalBudgetController.text) ?? 0;
    if (totalBudget == 0) return;

    // Apply 50/30/20 rule as default
    final needs = totalBudget * 0.5; // 50%
    final wants = totalBudget * 0.3;  // 30%
    final savings = totalBudget * 0.2; // 20%

    // Distribute among categories
    final needsCategories = ['Bills & Utilities', 'Healthcare', 'Transportation'];
    final wantsCategories = ['Food & Dining', 'Entertainment', 'Shopping', 'Travel'];
    
    final needsPerCategory = needs / needsCategories.length;
    final wantsPerCategory = wants / wantsCategories.length;

    for (String category in _categories) {
      if (needsCategories.contains(category)) {
        _categoryControllers[category]!.text = needsPerCategory.toStringAsFixed(0);
      } else if (wantsCategories.contains(category)) {
        _categoryControllers[category]!.text = wantsPerCategory.toStringAsFixed(0);
      } else {
        _categoryControllers[category]!.text = '0';
      }
    }
  }

  void _applyQuickSetup(String type) {
    final totalBudget = double.tryParse(_totalBudgetController.text) ?? 0;
    if (totalBudget == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a total budget first')),
      );
      return;
    }

    Map<String, double> allocations = {};

    switch (type) {
      case 'conservative':
        allocations = {
          'Food & Dining': totalBudget * 0.15,
          'Transportation': totalBudget * 0.20,
          'Entertainment': totalBudget * 0.10,
          'Shopping': totalBudget * 0.05,
          'Bills & Utilities': totalBudget * 0.30,
          'Healthcare': totalBudget * 0.10,
          'Education': totalBudget * 0.05,
          'Travel': totalBudget * 0.03,
          'Other': totalBudget * 0.02,
        };
        break;
      case 'balanced':
        allocations = {
          'Food & Dining': totalBudget * 0.20,
          'Transportation': totalBudget * 0.15,
          'Entertainment': totalBudget * 0.15,
          'Shopping': totalBudget * 0.10,
          'Bills & Utilities': totalBudget * 0.25,
          'Healthcare': totalBudget * 0.08,
          'Education': totalBudget * 0.04,
          'Travel': totalBudget * 0.03,
          'Other': totalBudget * 0.00,
        };
        break;
    }

    for (String category in allocations.keys) {
      if (_categoryControllers.containsKey(category)) {
        _categoryControllers[category]!.text = allocations[category]!.toStringAsFixed(0);
      }
    }
  }

  Future<void> _saveBudget() async {
    try {
      setState(() => _isLoading = true);

      final totalBudget = double.tryParse(_totalBudgetController.text) ?? 0;
      if (totalBudget <= 0) {
        throw Exception('Please enter a valid total budget amount');
      }

      final categoryBudgets = <String, double>{};
      double categoryTotal = 0;

      for (String category in _categories) {
        final amount = double.tryParse(_categoryControllers[category]!.text) ?? 0;
        if (amount > 0) {
          categoryBudgets[category] = amount;
          categoryTotal += amount;
        }
      }

      if (categoryTotal > totalBudget) {
        throw Exception('Category budgets exceed total budget');
      }

      await _firebaseService.setMonthlyBudget(
        year: widget.currentFilter.year,
        month: widget.currentFilter.month,
        totalBudget: totalBudget,
        categoryBudgets: categoryBudgets,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget saved successfully!'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _BudgetTip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BudgetTip({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gradientStart.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.gradientStart,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
