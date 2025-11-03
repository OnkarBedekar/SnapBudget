import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class DateFilter {
  final int month;
  final int year;

  DateFilter({required this.month, required this.year});

  DateTime get startDate => DateTime(year, month, 1);
  DateTime get endDate => DateTime(year, month + 1, 0, 23, 59, 59);

  bool get isCurrentMonth {
    final now = DateTime.now();
    return month == now.month && year == now.year;
  }

  String get displayText {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[month - 1]} $year';
  }

  DateFilter copyWith({int? month, int? year}) {
    return DateFilter(
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  DateFilter previousMonth() {
    if (month == 1) {
      return DateFilter(month: 12, year: year - 1);
    }
    return DateFilter(month: month - 1, year: year);
  }

  DateFilter nextMonth() {
    if (month == 12) {
      return DateFilter(month: 1, year: year + 1);
    }
    return DateFilter(month: month + 1, year: year);
  }

  static DateFilter current() {
    final now = DateTime.now();
    return DateFilter(month: now.month, year: now.year);
  }
}

class DateFilterWidget extends StatelessWidget {
  final DateFilter currentFilter;
  final Function(DateFilter) onFilterChanged;
  final bool showPickerButton;

  const DateFilterWidget({
    Key? key,
    required this.currentFilter,
    required this.onFilterChanged,
    this.showPickerButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canGoNext = currentFilter.month < now.month || currentFilter.year < now.year;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => onFilterChanged(currentFilter.previousMonth()),
            icon: const Icon(Icons.chevron_left),
            color: AppColors.gradientStart,
            tooltip: 'Previous month',
          ),
          
          Expanded(
            child: GestureDetector(
              onTap: showPickerButton ? () => _showMonthYearPicker(context) : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentFilter.displayText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (showPickerButton) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.gradientStart,
                    ),
                  ],
                  if (currentFilter.isCurrentMonth) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.income.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.income,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          IconButton(
            onPressed: canGoNext ? () => onFilterChanged(currentFilter.nextMonth()) : null,
            icon: const Icon(Icons.chevron_right),
            color: canGoNext ? AppColors.gradientStart : AppColors.textSecondary.withOpacity(0.3),
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context) {    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Month & Year'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: YearMonthPicker(
            initialFilter: currentFilter,
            onSelected: (filter) {
              Navigator.pop(context);
              onFilterChanged(filter);
            },
          ),
        ),
      ),
    );
  }
}

class YearMonthPicker extends StatefulWidget {
  final DateFilter initialFilter;
  final Function(DateFilter) onSelected;

  const YearMonthPicker({
    Key? key,
    required this.initialFilter,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<YearMonthPicker> createState() => _YearMonthPickerState();
}

class _YearMonthPickerState extends State<YearMonthPicker> {
  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialFilter.year;
    selectedMonth = widget.initialFilter.month;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(5, (i) => now.year - i);
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Column(
      children: [
        // Year selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<int>(
            value: selectedYear,
            isExpanded: true,
            underline: const SizedBox(),
            items: years.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text(
                  year.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
            onChanged: (year) {
              setState(() {
                selectedYear = year!;
              });
            },
          ),
        ),

        const SizedBox(height: 16),

        // Month grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = month == selectedMonth && selectedYear == widget.initialFilter.year;
              final isFuture = selectedYear > now.year || 
                             (selectedYear == now.year && month > now.month);

              return InkWell(
                onTap: isFuture ? null : () {
                  widget.onSelected(DateFilter(month: month, year: selectedYear));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.gradientStart 
                        : isFuture 
                            ? AppColors.surfaceLight.withOpacity(0.5)
                            : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      months[index].substring(0, 3),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                            ? Colors.white 
                            : isFuture 
                                ? AppColors.textSecondary.withOpacity(0.5)
                                : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}