import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/income_source.dart';
import '../services/firebase_service.dart';
import '../services/date_helper.dart';
import 'home_screen.dart';
import '../providers/dashboard_provider.dart';

class IncomeTrackerScreen extends StatefulWidget {
  const IncomeTrackerScreen({Key? key}) : super(key: key);

  @override
  State<IncomeTrackerScreen> createState() => _IncomeTrackerScreenState();
}

class _IncomeTrackerScreenState extends State<IncomeTrackerScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<IncomeSource>>(
          stream: _firebaseService.getIncomeSources(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.gradientStart),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final incomeSources = snapshot.data!;
            final primaryIncome = incomeSources.first;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: CommonAppBar(
                    title: 'Income Tracker',
                    subtitle: 'Manage your earnings',
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildPaydayCard(primaryIncome),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildCurrentPeriodStats(primaryIncome),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildQuickStats(primaryIncome),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddHoursDialog(primaryIncome),
                            icon: const Icon(Icons.add),
                            label: const Text('Log Hours'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColors.income,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showEditIncomeDialog(primaryIncome),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.gradientStart,
                              side: const BorderSide(color: AppColors.gradientStart),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.income, Color(0xFF0D9488)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.income.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddIncomeDialog,
          foregroundColor: Colors.white, 
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const CommonAppBar(
          title: 'Income Tracker',
          subtitle: 'Manage your earnings',
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 80,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Income Sources Yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Add your first income source to start tracking your payday!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showAddIncomeDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Income Source'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.income,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaydayCard(IncomeSource income) {
    final nextPayday = DateHelper.getNextPayday(income.payDates);
    final daysUntil = DateHelper.getDaysUntilPayday(income.payDates);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Next Payday',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$daysUntil days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            DateHelper.formatDate(nextPayday),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Expected: ${DateHelper.formatCurrency(income.projectedIncome)}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPeriodStats(IncomeSource income) {
    final payPeriod = DateHelper.getCurrentPayPeriod(income.payDates);
    final hoursProgress = income.hoursWorked / income.targetHours;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
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
          Text(
            'Current Period (${DateHelper.formatDate(payPeriod.start)} - ${DateHelper.formatDate(payPeriod.end)})',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hours Worked',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                '${income.hoursWorked.toStringAsFixed(1)} / ${income.targetHours.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: hoursProgress > 1 ? 1 : hoursProgress,
              minHeight: 12,
              backgroundColor: AppColors.surfaceLight,
              color: AppColors.income,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Hourly Rate', DateHelper.formatCurrency(income.hourlyRate)),
              _buildStatItem('Earned So Far', DateHelper.formatCurrency(income.earnedSoFar)),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Projected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                DateHelper.formatCurrency(income.projectedIncome),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.income,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(IncomeSource income) {
    final hoursRemaining = income.targetHours - income.hoursWorked;

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
        children: [
          Expanded(
            child: _buildQuickStatCard(
              'Hours Left',
              hoursRemaining.toStringAsFixed(0),
              Icons.access_time,
              AppColors.accentBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickStatCard(
              'Per Hour',
              DateHelper.formatCurrency(income.hourlyRate),
              Icons.attach_money,
              AppColors.income,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddIncomeDialog() {
    final jobNameController = TextEditingController();
    final hourlyRateController = TextEditingController();
    final targetHoursController = TextEditingController(text: '80');
    List<int> selectedPayDates = [7, 22];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(  // IMPORTANT: Use StatefulBuilder
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Income Source'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: jobNameController,
                  decoration: InputDecoration(
                    labelText: 'Job Name',
                    hintText: 'e.g., Part-time at Starbucks',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hourlyRateController,
                  decoration: InputDecoration(
                    labelText: 'Hourly Rate',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetHoursController,
                  decoration: InputDecoration(
                    labelText: 'Target Hours per Period',
                    hintText: 'e.g., 80',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pay Dates (Select days of month)',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [7, 15, 22, 30].map((day) {
                    return FilterChip(
                      label: Text('$day'),
                      selected: selectedPayDates.contains(day),
                      selectedColor: AppColors.gradientStart,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setDialogState(() {  // Use setDialogState to update dialog
                          if (selected) {
                            if (!selectedPayDates.contains(day)) {
                              selectedPayDates.add(day);
                              selectedPayDates.sort();
                            }
                          } else {
                            selectedPayDates.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (selectedPayDates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Please select at least one pay date',
                      style: TextStyle(color: AppColors.expense, fontSize: 12),
                    ),
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
                if (jobNameController.text.isEmpty || hourlyRateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                if (selectedPayDates.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one pay date')),
                  );
                  return;
                }

                final income = IncomeSource(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: _firebaseService.currentUserId ?? '',
                  jobName: jobNameController.text,
                  hourlyRate: double.parse(hourlyRateController.text),
                  payDates: selectedPayDates,
                  targetHours: double.parse(targetHoursController.text),
                  createdAt: DateTime.now(),
                );

                await _firebaseService.addIncomeSource(income);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Income source added!'),
                      backgroundColor: AppColors.income,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.income,
                foregroundColor: Colors.white,  // ADD THIS
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHoursDialog(IncomeSource income) {
    final hoursController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Hours Worked'),
        content: TextField(
          controller: hoursController,
          decoration: InputDecoration(
            labelText: 'Hours',
            hintText: 'e.g., 8',
            suffix: const Text('hrs'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (hoursController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter hours')),
                );
                return;
              }

              final additionalHours = double.parse(hoursController.text);
              final updatedIncome = income.copyWith(
                hoursWorked: income.hoursWorked + additionalHours,
              );

              await _firebaseService.updateIncomeSource(updatedIncome);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added $additionalHours hours! Total: ${updatedIncome.hoursWorked.toStringAsFixed(1)} hrs',
                    ),
                    backgroundColor: AppColors.income,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.income,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Hours'),
          ),
        ],
      ),
    );
  }

  void _showEditIncomeDialog(IncomeSource income) {
    final jobNameController = TextEditingController(text: income.jobName);
    final hourlyRateController = TextEditingController(text: income.hourlyRate.toString());
    final targetHoursController = TextEditingController(text: income.targetHours.toString());
    final hoursWorkedController = TextEditingController(text: income.hoursWorked.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Income Source'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jobNameController,
                decoration: InputDecoration(
                  labelText: 'Job Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hourlyRateController,
                decoration: InputDecoration(
                  labelText: 'Hourly Rate',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetHoursController,
                decoration: InputDecoration(
                  labelText: 'Target Hours',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hoursWorkedController,
                decoration: InputDecoration(
                  labelText: 'Hours Worked',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firebaseService.deleteIncomeSource(income.id);
                
                // Refresh dashboard provider if available
                if (context.mounted) {
                  try {
                    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
                    await dashboardProvider.refresh();
                  } catch (e) {
                    // Provider might not be available, that's okay
                  }
                }
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Income source deleted'),
                      backgroundColor: AppColors.income,
                    ),
                  );
                }
              } catch (e, stackTrace) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting income source: ${e.toString()}'),
                      backgroundColor: AppColors.expense,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedIncome = income.copyWith(
                jobName: jobNameController.text,
                hourlyRate: double.parse(hourlyRateController.text),
                targetHours: double.parse(targetHoursController.text),
                hoursWorked: double.parse(hoursWorkedController.text),
              );

              await _firebaseService.updateIncomeSource(updatedIncome);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Income source updated!'),
                    backgroundColor: AppColors.income,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.income,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}