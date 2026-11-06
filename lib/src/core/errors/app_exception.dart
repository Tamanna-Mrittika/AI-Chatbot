/// Base class for every error surfaced to the presentation layer.
///
/// Data sources translate transport specific failures (socket errors, non-200
/// responses, malformed payloads) into one of these subclasses so that widgets
/// only ever have to render an [AppException.message].
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// Message safe to render directly in the UI.
  final String message;

  /// Underlying error, kept for logging only.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// The device could not reach the API at all.
final class NetworkException extends AppException {
  const NetworkException({super.cause})
    : super(
        'Could not reach Gemini. Check your internet connection and '
        'try again.',
      );
}

/// The API key is missing, malformed or rejected.
final class AuthException extends AppException {
  const AuthException([
    super.message =
        'Your API key was rejected. '
        'Open Settings and paste a valid key.',
  ]);
}

/// The free-tier quota or the per-minute rate limit was exhausted.
final class RateLimitException extends AppException {
  const RateLimitException()
    : super(
        'Rate limit reached. The free tier allows a limited number of '
        'requests per minute — wait a moment and retry.',
      );
}

/// The prompt or the response was blocked by the safety filters.
final class ContentBlockedException extends AppException {
  const ContentBlockedException(String reason)
    : super('The response was blocked ($reason).');
}

/// The API answered, but with an unexpected status or body.
final class ApiException extends AppException {
  const ApiException(super.message, {this.statusCode, super.cause});

  final int? statusCode;
}

/// The response could not be parsed into the expected shape.
final class ParseException extends AppException {
  const ParseException({super.cause})
    : super('Received a malformed response from Gemini.');
}

/// User input failed a domain rule; rendered as a field-level form error.
final class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Local persistence failed.
final class StorageException extends AppException {
  const StorageException({super.cause})
    : super('Could not save your data on this device.');
}
