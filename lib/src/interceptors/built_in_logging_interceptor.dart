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

    print('╔══════════ SDK REQUEST ══════════');
    print('║ METHOD: ${req.method}');
    print('║ URL: ${req.endpoint}');
    print('║ QUERY: ${req.query}');
    if (headers != null) print('║ HEADERS: $headers');
    if (body != null) print('║ BODY: $body');
    print('╚═════════════════════════════════');

    return req;
  }

  @override
  Future<HttpResponse?> onResponse(HttpRequest req, HttpResponse res) async {
    if (!options.enabled) return res;

    final headers = options.logHeaders ? res.headers : null;
    final data = options.logBody ? _maskBody(res.data) : null;

    print('╔══════════ SDK RESPONSE ═════════');
    print('║ METHOD: ${req.method}');
    print('║ URL: ${req.endpoint}');
    print('║ STATUS: ${res.statusCode}');
    if (headers != null) print('║ HEADERS: $headers');
    if (data != null) print('║ RESPONSE: $data');
    print('╚═════════════════════════════════');

    return res;
  }

  @override
  Future<SdkError?> onError(HttpRequest req, SdkError error) async {
    if (!options.enabled) return error;

    print('╔══════════ SDK ERROR ════════════');
    print('║ METHOD: ${req.method}');
    print('║ URL: ${req.endpoint}');
    print('║ STATUS: ${error.statusCode}');
    print('║ TYPE: ${error.type}');
    print('║ MESSAGE: ${error.message}');
    if (options.logBody && error.raw != null) {
      print('║ RAW: ${_maskBody(error.raw)}');
    }
    print('╚═════════════════════════════════');

    return error;
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
