import 'enums.dart';

/// Describes an SDK failure in a transport-agnostic way.
class SdkError {
  /// The high-level category of failure.
  final ErrorType type;

  /// Human-readable error message.
  final String message;

  /// HTTP status code when one was available.
  final int? statusCode;

  /// Raw error payload or response body, when preserved.
  final dynamic raw;

  /// Creates an SDK error value.
  const SdkError({
    required this.type,
    required this.message,
    this.statusCode,
    this.raw,
  });
}
