typedef IsBodySuccess = bool Function(Map<String, dynamic> json, int? statusCode);

class SdkContract {
  final Set<int> successStatusCodes;
  final String dataPath;
  final String messagePath;
  final IsBodySuccess isBodySuccess;

  const SdkContract({
    required this.successStatusCodes,
    required this.dataPath,
    required this.messagePath,
    required this.isBodySuccess,
  });

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