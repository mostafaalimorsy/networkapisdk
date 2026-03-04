import 'enums.dart';
import 'sdk_error.dart';

class SdkResponse {
  final bool ok;
  final int? statusCode;
  final ResponseSource source;
  final String? message;
  final dynamic data; // دايمًا JSON-friendly
  final SdkError? error;
  final Map<String, dynamic> meta;

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