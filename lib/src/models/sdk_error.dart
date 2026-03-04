import 'enums.dart';

class SdkError {
  final ErrorType type;
  final String message;
  final int? statusCode;
  final dynamic raw;

  const SdkError({
    required this.type,
    required this.message,
    this.statusCode,
    this.raw,
  });
}