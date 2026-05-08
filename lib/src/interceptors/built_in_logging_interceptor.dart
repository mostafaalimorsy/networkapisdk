import 'dart:developer' as developer;
import '../config/logging_options.dart';
import '../http/http_client.dart';
import '../models/sdk_error.dart';
import 'sdk_interceptor.dart';

/// Built-in SDK logging interceptor.
class BuiltInLoggingInterceptor implements SdkInterceptor {
  final LoggingOptions options;

  const BuiltInLoggingInterceptor(this.options);

  @override
  Future<HttpRequest?> onRequest(HttpRequest req) async {
    if (!options.enabled) return req;

    final headers = options.logHeaders ? _maskHeaders(req.headers) : null;
    final body = options.logBody ? _maskBody(req.body.value) : null;

    _log('╔══════════ SDK REQUEST ══════════');
    _log('║ METHOD: ${req.method}');
    _log('║ URL: ${req.endpoint}');
    _log('║ QUERY: ${req.query}');
    if (headers != null) _log('║ HEADERS: $headers');
    if (body != null) _log('║ BODY: $body');
    _log('╚═════════════════════════════════');

    return req;
  }

  @override
  Future<HttpResponse?> onResponse(HttpRequest req, HttpResponse res) async {
    if (!options.enabled) return res;

    final headers = options.logHeaders ? res.headers : null;
    final data = options.logBody ? _maskBody(res.data) : null;

    _log('╔══════════ SDK RESPONSE ═════════');
    _log('║ METHOD: ${req.method}');
    _log('║ URL: ${req.endpoint}');
    _log('║ STATUS: ${res.statusCode}');
    if (headers != null) _log('║ HEADERS: $headers');
    if (data != null) _log('║ RESPONSE: $data');
    _log('╚═════════════════════════════════');

    return res;
  }

  @override
  Future<SdkError?> onError(HttpRequest req, SdkError error) async {
    if (!options.enabled) return error;

    _log('╔══════════ SDK ERROR ════════════');
    _log('║ METHOD: ${req.method}');
    _log('║ URL: ${req.endpoint}');
    _log('║ STATUS: ${error.statusCode}');
    _log('║ TYPE: ${error.type}');
    _log('║ MESSAGE: ${error.message}');
    if (options.logBody && error.raw != null) {
      _log('║ RAW: ${_maskBody(error.raw)}');
    }
    _log('╚═════════════════════════════════');

    return error;
  }

  void _log(String message) {
    developer.log(message, name: 'network_api_sdk');
  }

  Map<String, String>? _maskHeaders(Map<String, String>? headers) {
    if (headers == null) return null;
    if (!options.maskSensitiveData) return headers;

    final result = <String, String>{...headers};

    if (result.containsKey('Authorization')) {
      result['Authorization'] = '***';
    }

    return result;
  }

  dynamic _maskBody(dynamic value) {
    if (!options.maskSensitiveData) return value;

    if (value is Map<String, dynamic>) {
      final map = <String, dynamic>{...value};

      for (final key in map.keys.toList()) {
        final lower = key.toLowerCase();
        if (lower.contains('password') ||
            lower.contains('token') ||
            lower.contains('authorization')) {
          map[key] = '***';
        }
      }

      return map;
    }

    return value;
  }
}
