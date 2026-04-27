/// Centralized error handling for consistent user messaging.
/// Converts various error types into user-friendly messages.
class ErrorHandler {
  /// Get a user-friendly error message from any exception.
  ///
  /// Returns a generic, non-technical message suitable for display.
  /// Logs the original error for debugging purposes.
  static String getUserMessage(Object error, [StackTrace? stackTrace]) {
    // Firebase-specific errors
    if (error.toString().contains('permission-denied')) {
      return 'You don\'t have permission to perform this action.';
    }
    if (error.toString().contains('not-found')) {
      return 'The session or resource you\'re looking for no longer exists.';
    }
    if (error.toString().contains('unavailable')) {
      return 'The service is temporarily unavailable. Please try again.';
    }
    if (error.toString().contains('Already submitted')) {
      return 'You\'ve already submitted an answer for this question.';
    }
    if (error.toString().contains('network')) {
      return 'Network connection error. Please check your internet and try again.';
    }
    if (error.toString().contains('timeout')) {
      return 'The request took too long. Please try again.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again or contact support if the problem persists.';
  }

  /// Log error details for debugging/monitoring.
  /// In production, this should send to a logging service (Sentry, etc.)
  static void logError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
  }) {
    // TODO: In production, send to Sentry or similar
    print('❌ Error${context != null ? ' in $context' : ''}: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}
