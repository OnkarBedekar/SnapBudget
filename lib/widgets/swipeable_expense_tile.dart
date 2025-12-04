import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../services/date_helper.dart';
import '../services/firebase_service.dart';
import '../screens/home_screen.dart';
import '../providers/dashboard_provider.dart';
import '../utils/error_handler.dart';
import '../utils/constants.dart';

class SwipeableExpenseTile extends StatefulWidget {
  final Expense expense;
  final VoidCallback? onExpenseUpdated;

  const SwipeableExpenseTile({
    Key? key,
    required this.expense,
    this.onExpenseUpdated,
  }) : super(key: key);

  @override
  State<SwipeableExpenseTile> createState() => _SwipeableExpenseTileState();
}

class _SwipeableExpenseTileState extends State<SwipeableExpenseTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(widget.expense.id),
        direction: DismissDirection.horizontal,
        background: _buildSwipeBackground('Edit', Icons.edit, AppColors.accentBlue),
        secondaryBackground: _buildSwipeBackground('Delete', Icons.delete, AppColors.expense),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Edit action
            _showEditDialog();
            return false; // Don't actually dismiss the item
          } else if (direction == DismissDirection.endToStart) {
            // Delete action
            _showDeleteConfirmation();
            return false; // Don't actually dismiss the item
          }
          return false;
        },
        child: _buildExpenseTile(),
      ),
    );
  }

  Widget _buildSwipeBackground(String label, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: label == 'Edit' ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getCategoryColor(widget.expense.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getCategoryIcon(widget.expense.category),
              color: _getCategoryColor(widget.expense.category),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.expense.description ?? widget.expense.category,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateHelper.formatDate(widget.expense.date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '- ${DateHelper.formatCurrency(widget.expense.amount)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final amountController = TextEditingController(text: widget.expense.amount.toString());
    final descriptionController = TextEditingController(text: widget.expense.description ?? '');
    String selectedCategory = widget.expense.category;
    DateTime selectedDate = widget.expense.date;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Food', child: Text('Food')),
                    DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                    DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                    DropdownMenuItem(value: 'Entertainment', child: Text('Entertainment')),
                    DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                    DropdownMenuItem(value: 'Healthcare', child: Text('Healthcare')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text(DateHelper.formatDate(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
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
                if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an amount')),
                  );
                  return;
                }

                try {
                  final updatedExpense = Expense(
                    id: widget.expense.id,
                    userId: widget.expense.userId,
                    amount: double.parse(amountController.text),
                    category: selectedCategory,
                    description: descriptionController.text.isEmpty 
                        ? null 
                        : descriptionController.text,
                    photoUrl: widget.expense.photoUrl,
                    date: selectedDate,
                    createdAt: widget.expense.createdAt,
                  );

                  // Update the expense using the new update method
                  await FirebaseService().updateExpense(updatedExpense, oldExpense: widget.expense);

                  // Refresh dashboard provider to update budget and totals
                  if (context.mounted) {
                    try {
                      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
                      await dashboardProvider.refresh(forceBudgetRefresh: true);
                    } catch (e) {
                      // Provider might not be available, that's okay
                    }
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ErrorHandler.showSuccessSnackBar(
                      context,
                      AppConstants.successExpenseUpdated,
                    );
                    widget.onExpenseUpdated?.call();
                  }
                } catch (e, stackTrace) {
                  if (context.mounted) {
                    ErrorHandler.handleError(context, e, stackTrace: stackTrace);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.accentBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete "${widget.expense.description ?? widget.expense.category}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseService().deleteExpense(widget.expense.id);
                
                // Refresh dashboard provider to update budget and totals
                if (context.mounted) {
                  try {
                    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
                    await dashboardProvider.refresh(forceBudgetRefresh: true);
                  } catch (e) {
                    // Provider might not be available, that's okay
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ErrorHandler.showSuccessSnackBar(
                    context,
                    AppConstants.successExpenseDeleted,
                  );
                  widget.onExpenseUpdated?.call();
                }
              } catch (e, stackTrace) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ErrorHandler.handleError(context, e, stackTrace: stackTrace);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.expense,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Icons.restaurant_rounded;
      case 'transport': return Icons.directions_car_rounded;
      case 'shopping': return Icons.shopping_bag_rounded;
      case 'entertainment': return Icons.movie_rounded;
      case 'bills': return Icons.receipt_rounded;
      case 'healthcare': return Icons.medical_services_rounded;
      default: return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food': return const Color(0xFFFF9800);
      case 'transport': return AppColors.accentBlue;
      case 'shopping': return AppColors.accentPink;
      case 'entertainment': return const Color(0xFFE91E63);
      case 'bills': return const Color(0xFF795548);
      case 'healthcare': return AppColors.expense;
      default: return AppColors.textSecondary;
    }
  }
}
