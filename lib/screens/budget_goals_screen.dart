import 'package:flutter/material.dart';
import '../models/budget_goal.dart';
import '../services/firebase_service.dart';
import '../services/date_helper.dart';
import 'home_screen.dart';

class BudgetGoalsScreen extends StatefulWidget {
  const BudgetGoalsScreen({Key? key}) : super(key: key);

  @override
  State<BudgetGoalsScreen> createState() => _BudgetGoalsScreenState();
}

class _BudgetGoalsScreenState extends State<BudgetGoalsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budget Goals'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<BudgetGoal>>(
        stream: _firebaseService.getBudgetGoals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gradientEnd),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final goals = snapshot.data!;
          final activeGoals = goals.where((g) => !g.isCompleted).toList();
          final completedGoals = goals.where((g) => g.isCompleted).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activeGoals.isNotEmpty) ...[
                  const Text(
                    'Active Goals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...activeGoals.map((goal) => _buildGoalCard(goal)),
                ],
                if (completedGoals.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Completed Goals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...completedGoals.map((goal) => _buildGoalCard(goal)),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
        foregroundColor: Colors.white,
        backgroundColor: AppColors.gradientEnd,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            const Text(
              'No Budget Goals Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Set goals to track your savings and spending targets',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _showAddGoalDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Goal'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.gradientEnd,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BudgetGoal goal) {
    final progress = goal.progressPercentage / 100;
    final isCompleted = goal.isCompleted;
    final daysLeft = goal.daysRemaining;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: isCompleted
            ? Border.all(color: AppColors.income, width: 2)
            : null,
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
              // Only show icon and name for savings goals
              if (goal.category == 'savings') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(goal.colorValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(goal.iconName),
                    color: Color(goal.colorValue),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCategoryLabel(goal.category),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // For expense limit goals, show a simple indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.trending_down,
                    color: AppColors.expense,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Limit',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Auto-tracks spending',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.income,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateHelper.formatCurrency(goal.currentAmount),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(goal.colorValue),
                ),
              ),
              Text(
                'of ${DateHelper.formatCurrency(goal.targetAmount)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              color: isCompleted ? AppColors.income : Color(goal.colorValue),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.progressPercentage.toStringAsFixed(0)}% complete',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (!isCompleted)
                Text(
                  daysLeft > 0 ? '$daysLeft days left' : 'Overdue',
                  style: TextStyle(
                    fontSize: 13,
                    color: daysLeft > 0 ? AppColors.textSecondary : AppColors.expense,
                    fontWeight: daysLeft > 0 ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Show different UI based on goal type
              if (goal.category == 'savings') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showUpdateProgressDialog(goal),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Update Progress'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gradientEnd,
                      side: const BorderSide(color: AppColors.gradientEnd),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (goal.category == 'expense_limit') ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Auto-tracks expenses',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                onPressed: () => _showDeleteDialog(goal),
                icon: const Icon(Icons.delete_outline),
                color: AppColors.expense,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    String selectedCategory = 'savings';
    DateTime endDate = DateTime.now().add(const Duration(days: 30));
    int selectedColorIndex = 0;
    int selectedIconIndex = 0;

    final colors = [
      AppColors.gradientEnd,
      AppColors.income,
      AppColors.expense,
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
    ];

    final icons = [
      'savings',
      'shopping_cart',
      'flight',
      'phone_iphone',
      'home',
      'directions_car',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(selectedCategory == 'expense_limit' ? 'Create Expense Limit' : 'Create Budget Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Only show name field for savings goals
                if (selectedCategory == 'savings') ...[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Name',
                      hintText: 'e.g., Save for Vacation',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'savings', child: Text('Savings Goal')),
                    DropdownMenuItem(value: 'expense_limit', child: Text('Expense Limit')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(DateHelper.formatDate(endDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        endDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Only show color and icon selection for savings goals
                if (selectedCategory == 'savings') ...[
                  const Text('Choose Color', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: colors.asMap().entries.map((entry) {
                      int index = entry.key;
                      Color color = entry.value;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColorIndex = index),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: selectedColorIndex == index
                                ? Border.all(color: Colors.black, width: 3)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Choose Icon', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: icons.asMap().entries.map((entry) {
                      int index = entry.key;
                      String iconName = entry.value;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedIconIndex = index),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedIconIndex == index
                                ? AppColors.gradientEnd.withOpacity(0.2)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconData(iconName),
                            color: selectedIconIndex == index
                                ? AppColors.gradientEnd
                                : Colors.grey[600],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate fields based on category
                if (selectedCategory == 'savings' && nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a goal name')),
                  );
                  return;
                }
                
                if (targetController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a target amount')),
                  );
                  return;
                }

                final goal = BudgetGoal(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: _firebaseService.currentUserId ?? '',
                  name: selectedCategory == 'savings' ? nameController.text : 'Expense Limit',
                  targetAmount: double.parse(targetController.text),
                  category: selectedCategory,
                  startDate: DateTime.now(),
                  endDate: endDate,
                  iconName: selectedCategory == 'savings' ? icons[selectedIconIndex] : null,
                  colorValue: selectedCategory == 'savings' ? colors[selectedColorIndex].value : AppColors.expense.value,
                  createdAt: DateTime.now(),
                );

                await _firebaseService.addBudgetGoal(goal);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(selectedCategory == 'expense_limit' 
                          ? 'Expense limit created successfully!' 
                          : 'Goal created successfully!'),
                      backgroundColor: AppColors.income,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white,backgroundColor: AppColors.gradientEnd),
              child: Text(selectedCategory == 'expense_limit' ? 'Create Expense Limit' : 'Create Goal'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateProgressDialog(BudgetGoal goal) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current: ${DateHelper.formatCurrency(goal.currentAmount)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Add Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty) return;

              final addAmount = double.parse(amountController.text);
              final updatedGoal = goal.copyWith(
                currentAmount: goal.currentAmount + addAmount,
              );

              await _firebaseService.updateBudgetGoal(updatedGoal);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress updated!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(foregroundColor: Colors.white,backgroundColor: AppColors.income),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BudgetGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firebaseService.deleteBudgetGoal(goal.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Goal deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(foregroundColor: Colors.white,backgroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'savings':
        return Icons.savings;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'flight':
        return Icons.flight;
      case 'phone_iphone':
        return Icons.phone_iphone;
      case 'home':
        return Icons.home;
      case 'directions_car':
        return Icons.directions_car;
      default:
        return Icons.flag;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'savings':
        return 'Savings Goal';
      case 'expense_limit':
        return 'Expense Limit';
      case 'income_target':
        return 'Income Target';
      default:
        return category;
    }
  }
}