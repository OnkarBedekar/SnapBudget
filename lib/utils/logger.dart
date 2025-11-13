import 'package:logger/logger.dart' as logger_lib;

/// Centralized logging utility
class AppLogger {
  AppLogger._(); // Private constructor

  static logger_lib.Logger? _logger;

  /// Initialize logger
  static void init({bool enableInProduction = false}) {
    _logger = logger_lib.Logger(
      printer: logger_lib.PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: enableInProduction ? logger_lib.Level.info : logger_lib.Level.debug,
    );
  }

  /// Get logger instance
  static logger_lib.Logger get logger {
    _logger ??= logger_lib.Logger(
      printer: logger_lib.PrettyPrinter(),
    );
    return _logger!;
  }

  /// Log debug message
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal error
  static void f(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// Extension to easily log errors
extension ErrorLogging on Object {
  void logError(String message, [StackTrace? stackTrace]) {
    AppLogger.e(message, this, stackTrace);
  }
}

