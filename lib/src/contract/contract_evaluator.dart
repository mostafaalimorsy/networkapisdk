import '../config/sdk_contract.dart';
import '../models/enums.dart';
import '../models/sdk_error.dart';
import '../models/sdk_response.dart';

/// Applies an [SdkContract] to a normalized transport response.
///
/// This class is used internally by the SDK request layer.
class ContractEvaluator {
  /// The contract used for evaluation.
  final SdkContract contract;

  /// Creates a contract evaluator.
  const ContractEvaluator(this.contract);

  /// Evaluates a normalized response and returns an [SdkResponse].
  ///
  /// For successful JSON maps, [SdkContract.dataPath] is used to extract
  /// [SdkResponse.data]. If that path is missing, the full JSON map is returned
  /// instead.
  SdkResponse evaluate({
    required int? statusCode,
    required dynamic rawJson,
    required ResponseSource source,
  }) {
    final statusOk =
        statusCode != null && contract.successStatusCodes.contains(statusCode);

    // Case 1: Map JSON body -> apply contract rules
    if (rawJson is Map<String, dynamic>) {
      final bodyOk = contract.isBodySuccess(rawJson, statusCode);
      final ok = statusOk && bodyOk;

      final message = _resolveMessage(rawJson);

      if (!ok) {
        return SdkResponse(
          ok: false,
          statusCode: statusCode,
          source: source,
          message: message,
          data: null,
          error: SdkError(
            type: ErrorType.contract,
            message: message ?? 'Request failed (contract).',
            statusCode: statusCode,
            raw: rawJson,
          ),
        );
      }

      final extracted = _readPath(rawJson, contract.dataPath);
      final data = extracted ?? rawJson;

      return SdkResponse(
        ok: true,
        statusCode: statusCode,
        source: source,
        message: message,
        data: data,
      );
    }

    // Case 2: Non-map body (List/text-wrapper/etc.)
    if (statusOk) {
      return SdkResponse(
        ok: true,
        statusCode: statusCode,
        source: source,
        data: rawJson,
      );
    }

    return SdkResponse(
      ok: false,
      statusCode: statusCode,
      source: source,
      error: SdkError(
        type: ErrorType.contract,
        message: 'Request failed (contract).',
        statusCode: statusCode,
        raw: rawJson,
      ),
    );
  }

  String? _resolveMessage(Map<String, dynamic> json) {
    final direct = _readPath(json, contract.messagePath)?.toString();
    if (direct != null && direct.trim().isNotEmpty) {
      return direct;
    }

    final errors = json['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map<String, dynamic>) {
        final nested = first['message']?.toString();
        if (nested != null && nested.trim().isNotEmpty) {
          return nested;
        }
      }
    }

    return null;
  }

  dynamic _readPath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return null;
    final parts = path.split('.');
    dynamic cur = json;
    for (final p in parts) {
      if (cur is Map<String, dynamic> && cur.containsKey(p)) {
        cur = cur[p];
      } else {
        return null;
      }
    }
    return cur;
  }
}
