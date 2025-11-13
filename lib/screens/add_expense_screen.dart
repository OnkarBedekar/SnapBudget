import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibration/vibration.dart';
import 'dart:io';
import '../models/expense.dart';
import '../services/firebase_service.dart';
import '../services/date_helper.dart';
import 'home_screen.dart';
import '../services/notification_service.dart';
import '../services/ocr_service.dart';
import '../utils/error_handler.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  final _formKey = GlobalKey<FormState>();

  File? _imageFile;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = AppConstants.defaultCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isProcessing = false;

  final List<String> _categories = AppConstants.expenseCategories;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _isProcessing = true;
        });

        await _processReceiptImage(photo.path);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ErrorHandler.handleError(context, e, stackTrace: stackTrace);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _isProcessing = true;
        });

        await _processReceiptImage(image.path);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ErrorHandler.handleError(context, e, stackTrace: stackTrace);
      }
    }
  }

  Future<void> _processReceiptImage(String imagePath) async {
    try {
      final result = await _ocrService.extractReceiptData(imagePath);

      setState(() {
        _isProcessing = false;

        if (result['amount'] != null) {
          _amountController.text = result['amount'].toStringAsFixed(2);
        }

        if (result['date'] != null) {
          _selectedDate = result['date'];
        }
      });

      if (mounted) {
        String message = 'Receipt scanned!\n';
        if (result['amount'] != null) {
          message += 'Amount: \$${result['amount'].toStringAsFixed(2)}\n';
        }
        if (result['date'] != null) {
          message += 'Date: ${DateHelper.formatDate(result['date'])}';
        }

        if (result['amount'] != null || result['date'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.income,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not extract data. Please enter manually.'),
              backgroundColor: AppColors.neutral,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ErrorHandler.handleError(context, e, stackTrace: stackTrace);
      }
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final expense = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _firebaseService.currentUserId ?? '',
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        photoUrl: _imageFile?.path,
        date: _selectedDate,
        createdAt: DateTime.now(),
      );

      await _firebaseService.addExpense(expense);

      // Update expense limit goals automatically
      await _firebaseService.updateExpenseLimitGoals(expense);

      if (expense.amount > AppConstants.largeExpenseThreshold) {
        NotificationService().showLargeExpenseAlert(expense.amount);
      }

      // Refresh dashboard provider if available
      try {
        final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
        await dashboardProvider.refresh();
      } catch (e) {
        // Provider might not be available in this context, that's okay
      }

      // Haptic feedback for success
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: AppConstants.vibrationDuration);
      }

      setState(() {
        _imageFile = null;
        _amountController.clear();
        _descriptionController.clear();
        _selectedCategory = AppConstants.defaultCategory;
        _selectedDate = DateTime.now();
      });

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          AppConstants.successExpenseAdded,
        );
        // Navigate back after successful save
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ErrorHandler.handleError(context, e, stackTrace: stackTrace);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.expense),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    _buildCameraSection(),

                    if (_isProcessing)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.gradientStart.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.gradientStart,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Scanning receipt...',
                              style: TextStyle(
                                color: AppColors.gradientStart,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),
                    _buildAmountInput(),
                    const SizedBox(height: 16),
                    _buildCategorySelector(),
                    const SizedBox(height: 16),
                    _buildDescriptionInput(),
                    const SizedBox(height: 16),
                    _buildDateSelector(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveExpense,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.gradientStart,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Expense',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCameraSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_imageFile == null) ...[
            const Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Snap a receipt',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a photo or choose from gallery',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _imageFile!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: const Text('Retake'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _imageFile = null;
                      });
                    },
                    icon: const Icon(Icons.delete, size: 20),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: Validators.amount,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.expense,
            ),
            decoration: const InputDecoration(
              prefixText: '\$ ',
              prefixStyle: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.expense,
              ),
              hintText: '0.00',
              border: InputBorder.none,
              errorMaxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = category == _selectedCategory;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                selectedColor: const Color(0xFF2E7D32),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'e.g., Lunch at Chipotle',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateHelper.formatDate(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Change'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
            ),
          ),
        ],
      ),
    );
  }

}
