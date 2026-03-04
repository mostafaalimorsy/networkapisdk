import '../models/request_body.dart';

class HttpResponse {
  final int? statusCode;
  final Map<String, String> headers;
  final dynamic data; // raw from dio

  const HttpResponse({
    required this.statusCode,
    required this.headers,
    required this.data,
  });
  HttpResponse copyWith({
    int? statusCode,
    Map<String, String>? headers,
    Object? data,
  }) {
    return HttpResponse(
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      data: data ?? this.data,
    );
  }
}

class HttpRequest {
  final String endpoint;
  final String method;
  final Map<String, dynamic>? query;
  final Map<String, String>? headers;
  final RequestBody body;
  final ResponseTypeHint responseType;

  const HttpRequest({
    required this.endpoint,
    required this.method,
    this.query,
    this.headers,
    this.body = const RequestBody.none(),
    this.responseType = ResponseTypeHint.json,
  });
  HttpRequest copyWith({
    String? endpoint,
    String? method,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    RequestBody? body,
    ResponseTypeHint? responseType,
  }) {
    return HttpRequest(
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      query: query ?? this.query,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      responseType: responseType ?? this.responseType,
    );
  }
}

abstract class HttpClient {
  Future<HttpResponse> send(HttpRequest request);
}