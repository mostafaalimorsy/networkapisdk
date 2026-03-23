import 'enums.dart';
import 'sdk_error.dart';

/// Represents the normalized result returned by the SDK request APIs.
class SdkResponse {
  /// Whether the operation was successful according to HTTP and contract rules.
  final bool ok;

  /// HTTP status code when one was available.
  ///
  /// Queue fallbacks use `202`, cache fallbacks use `200`, and transport
  /// failures without a response use `0`.
  final int? statusCode;

  /// Where the result came from.
  final ResponseSource source;

  /// User-facing message extracted from the response contract when available.
  final String? message;

  /// Normalized response payload.
  ///
  /// The built-in pipeline returns JSON-friendly values such as decoded maps,
  /// lists, primitives, or wrapper maps for text and bytes.
  final dynamic data;

  /// Error details for unsuccessful responses.
  final SdkError? error;

  /// Extra metadata attached by SDK features.
  ///
  /// For example, auth helpers use this map to explain token extraction
  /// failures without throwing.
  final Map<String, dynamic> meta;

  /// Creates a normalized SDK response.
  const SdkResponse({
    required this.ok,
    required this.source,
    this.statusCode,
    this.message,
    this.data,
    this.error,
    this.meta = const {},
  });
}
