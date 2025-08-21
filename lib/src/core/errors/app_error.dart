class AppError implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.message,
    required this.type,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;

  static AppError handle(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) return error;

    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused')) {
      return AppError(
        message: 'Network connection error. Please check your internet connection.',
        type: ErrorType.network,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error.toString().contains('timeout') ||
        error.toString().contains('TimeoutException')) {
      return AppError(
        message: 'Request timed out. Please try again.',
        type: ErrorType.timeout,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error.toString().contains('not found') ||
        error.toString().contains('404')) {
      return AppError(
        message: 'Resource not found.',
        type: ErrorType.notFound,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error.toString().contains('unauthorized') ||
        error.toString().contains('401')) {
      return AppError(
        message: 'Unauthorized access. Please log in again.',
        type: ErrorType.unauthorized,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error.toString().contains('forbidden') ||
        error.toString().contains('403')) {
      return AppError(
        message: 'Access forbidden. You don\'t have permission to perform this action.',
        type: ErrorType.forbidden,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error.toString().contains('validation') ||
        error.toString().contains('400')) {
      return AppError(
        message: 'Invalid data provided. Please check your input.',
        type: ErrorType.validation,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Generic error handling
    return AppError(
      message: 'An unexpected error occurred. Please try again.',
      type: ErrorType.unknown,
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}

enum ErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  unknown,
}
