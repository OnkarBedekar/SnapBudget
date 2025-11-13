import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'logger.dart';

/// Centralized error handling utility
class ErrorHandler {
  ErrorHandler._(); // Private constructor

  /// Get user-friendly error message from exception
  static String getErrorMessage(dynamic error, {String? defaultMessage}) {
    if (error is FirebaseAuthException) {
      return _getFirebaseAuthErrorMessage(error);
    }

    if (error is FormatException) {
      return AppConstants.errorInvalidInput;
    }

    if (error.toString().contains('network') || 
        error.toString().contains('Network') ||
        error.toString().contains('socket')) {
      return AppConstants.errorNetwork;
    }

    if (error.toString().contains('permission') || 
        error.toString().contains('Permission')) {
      return AppConstants.errorPermissionDenied;
    }

    // Log unexpected errors
    AppLogger.e('Unexpected error', error);

    return defaultMessage ?? AppConstants.errorGeneric;
  }

  /// Get Firebase Auth error message
  static String _getFirebaseAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'weak-password':
        return AppConstants.validationPasswordTooShort;
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email or sign in.';
      case 'invalid-email':
        return AppConstants.validationEmailInvalid;
      case 'user-not-found':
        return 'No account found with this email. Please check your email or sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      default:
        return 'Authentication failed: ${error.message ?? AppConstants.errorAuth}';
    }
  }

  /// Show error snackbar
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = AppConstants.mediumNotificationDuration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = AppConstants.mediumNotificationDuration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    if (!context.mounted) return;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                child: Text(actionLabel),
                onPressed: () {
                  Navigator.of(context).pop();
                  onAction();
                },
              ),
          ],
        );
      },
    );
  }

  /// Handle error with logging and user notification
  static void handleError(
    BuildContext? context,
    dynamic error, {
    String? defaultMessage,
    StackTrace? stackTrace,
    bool showToUser = true,
  }) {
    // Log error
    AppLogger.e(
      defaultMessage ?? 'An error occurred',
      error,
      stackTrace,
    );

    // Show to user if context is available
    if (context != null && showToUser && context.mounted) {
      final message = getErrorMessage(error, defaultMessage: defaultMessage);
      showErrorSnackBar(context, message);
    }
  }
}

