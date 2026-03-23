/// Evaluates whether a decoded response body represents success.
///
/// The callback receives the normalized JSON body and the HTTP status code.
typedef IsBodySuccess = bool Function(
    Map<String, dynamic> json, int? statusCode);

/// Describes how the SDK should interpret a backend response contract.
///
/// The SDK uses this contract to extract user-facing data, resolve messages,
/// and determine whether a response should be treated as successful.
class SdkContract {
  /// HTTP status codes that are considered transport-level success.
  final Set<int> successStatusCodes;

  /// Dot-separated path used to extract the normalized response payload.
  final String dataPath;

  /// Dot-separated path used to extract a response message.
  final String messagePath;

  /// Additional body-level success evaluation applied to JSON map responses.
  final IsBodySuccess isBodySuccess;

  /// Creates an explicit response contract definition.
  const SdkContract({
    required this.successStatusCodes,
    required this.dataPath,
    required this.messagePath,
    required this.isBodySuccess,
  });

  /// Creates a common contract with optional success flag and error code checks.
  ///
  /// Defaults [successStatusCodes] to `200`, `201`, and `204`. When
  /// [successFlag] is provided, the body is only treated as successful if that
  /// field is `true`. When [errorCode] is provided, the body is only treated as
  /// successful if that field is `0` or missing.
  factory SdkContract.auto({
    Set<int>? successStatusCodes,
    required String data,
    required String message,
    String? successFlag,
    String? errorCode,
  }) {
    return SdkContract(
      successStatusCodes: successStatusCodes ?? {200, 201, 204},
      dataPath: data,
      messagePath: message,
      isBodySuccess: (json, _) {
        final flagOk = successFlag == null ? true : (json[successFlag] == true);
        final codeOk = errorCode == null ? true : ((json[errorCode] ?? 0) == 0);
        return flagOk && codeOk;
      },
    );
  }
}
