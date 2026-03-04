import '../http/http_client.dart';
import '../models/sdk_error.dart';

abstract class SdkInterceptor {
  const SdkInterceptor();

  Future<HttpRequest?> onRequest(HttpRequest req) async => null;

  Future<HttpResponse?> onResponse(HttpRequest req, HttpResponse res) async => null;

  Future<SdkError?> onError(HttpRequest req, SdkError err) async => null;
}