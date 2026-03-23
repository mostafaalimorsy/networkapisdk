import '../http/http_client.dart';
import '../models/sdk_error.dart';
import 'sdk_interceptor.dart';

/// Executes [SdkInterceptor] hooks in registration order.
///
/// This class is used internally by the SDK.
class InterceptorRunner {
  final List<SdkInterceptor> _list;

  /// Creates an immutable interceptor runner.
  InterceptorRunner(List<SdkInterceptor> list)
      : _list = List.unmodifiable(list);

  /// Runs request interceptors in order.
  Future<HttpRequest> runRequest(HttpRequest req) async {
    var current = req;
    for (final it in _list) {
      final next = await it.onRequest(current);
      if (next != null) current = next;
    }
    return current;
  }

  /// Runs response interceptors in order.
  Future<HttpResponse> runResponse(HttpRequest req, HttpResponse res) async {
    var current = res;
    for (final it in _list) {
      final next = await it.onResponse(req, current);
      if (next != null) current = next;
    }
    return current;
  }

  /// Runs error interceptors in order.
  Future<SdkError> runError(HttpRequest req, SdkError err) async {
    var current = err;
    for (final it in _list) {
      final next = await it.onError(req, current);
      if (next != null) current = next;
    }
    return current;
  }
}
