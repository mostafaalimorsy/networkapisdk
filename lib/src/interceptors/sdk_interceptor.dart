import '../http/http_client.dart';
import '../models/sdk_error.dart';

/// Hook points that can observe or mutate SDK requests and responses.
///
/// Interceptors run in the order provided to the SDK configuration. Returning
/// `null` from any hook keeps the current value unchanged.
abstract class SdkInterceptor {
  /// Creates an interceptor.
  const SdkInterceptor();

  /// Observes or replaces the outgoing request before it is sent.
  ///
  /// This runs after auth headers have been attached.
  Future<HttpRequest?> onRequest(HttpRequest req) async => null;

  /// Observes or replaces the transport response after normalization.
  Future<HttpResponse?> onResponse(HttpRequest req, HttpResponse res) async =>
      null;

  /// Observes or replaces an error produced from a thrown exception path.
  ///
  /// This does not run for contract failures that already produced an
  /// unsuccessful response object.
  Future<SdkError?> onError(HttpRequest req, SdkError err) async => null;
}
